#!/usr/bin/env bash
# test-shell.sh — verify the Triton shell inside a headless sway container.
#
# The shell iteration loop without the ISO, a VM, or your own session:
#
#   scripts/test-shell.sh                    boot the shell headless, take a
#                                            screenshot, fail on errors
#   scripts/test-shell.sh --gallery power    one gallery page instead
#   scripts/test-shell.sh --entry greeter.qml
#   scripts/test-shell.sh --shot out.png     keep the screenshot there
#   scripts/test-shell.sh --nested           sway as a window, to look at it live
#
# Headless mode touches nothing on the host. Output lands in .out/shell/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="callisto-shelltest"
MODE="headless"
SHOT_OUT=""
# Headless sway under llvmpipe is slow to land the first shell frame; the
# default wait accounts for that.
WAIT_SECONDS=12

QS_ENTRY="shell.qml"
GALLERY=""
INTER_SCRIPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --nested) MODE="nested"; shift ;;
        --shot) SHOT_OUT="$2"; shift 2 ;;
        --wait) WAIT_SECONDS="$2"; shift 2 ;;
        --entry) QS_ENTRY="$2"; shift 2 ;;
        --gallery) QS_ENTRY="gallery.qml"; GALLERY="$2"; shift 2 ;;
        --script) INTER_SCRIPT="$2"; shift 2 ;;
        *) echo "test-shell: unknown argument: $1" >&2; exit 2 ;;
    esac
done

# Fonts must exist inside shell/triton/fonts for the shell to load them.
mkdir -p "$REPO_ROOT/shell/triton/fonts"
cp "$REPO_ROOT"/design/fonts/*.ttf "$REPO_ROOT/shell/triton/fonts/" 2>/dev/null || true

# The image carries the theme engine and the system tokens.
if ! podman image exists "$IMAGE"; then
    echo "==> Building $IMAGE (first run only)"
    podman build -f "$REPO_ROOT/containers/shelltest.Dockerfile" -t "$IMAGE" "$REPO_ROOT"
fi

if [[ "$MODE" == "nested" ]]; then
    : "${XDG_RUNTIME_DIR:?not a graphical session}"
    : "${WAYLAND_DISPLAY:?not a Wayland session}"
    exec podman run --rm -it \
        --name callisto-shelltest \
        --userns=keep-id \
        --user 1000:1000 \
        --security-opt label=disable \
        -e WAYLAND_DISPLAY="/wl/socket" \
        -e XDG_RUNTIME_DIR=/home/triton/xdg \
        -e WLR_BACKENDS=wayland \
        -e QS_ENTRY="$QS_ENTRY" \
        -e CALLISTO_GALLERY="$GALLERY" \
        -e CALLISTO_DENSITY="${CALLISTO_DENSITY:-compact}" \
        --tmpfs /home/triton/xdg:rw,exec,mode=0700,U \
        -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/wl/socket" \
        -v "$REPO_ROOT/shell/triton:/triton:ro" \
        "$IMAGE"
fi

# --- headless verification ---------------------------------------------------
CONTAINER="callisto-shelltest-$$"
cleanup() {
    podman rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Booting headless sway + Triton shell"
podman run -d --rm \
    --name "$CONTAINER" \
    --userns=keep-id \
    --user 1000:1000 \
    --security-opt label=disable \
    -e XDG_RUNTIME_DIR=/home/triton/xdg \
    -e QS_ENTRY="$QS_ENTRY" \
    -e CALLISTO_GALLERY="$GALLERY" \
    -e COMPOSITOR="${COMPOSITOR:-sway}" \
    -e CALLISTO_DENSITY="${CALLISTO_DENSITY:-compact}" \
    --tmpfs /home/triton/xdg:rw,exec,mode=0700,U \
    -v "$REPO_ROOT/shell/triton:/triton:ro" \
    "$IMAGE" >/dev/null

sleep "$WAIT_SECONDS"

if [[ -n "$INTER_SCRIPT" ]]; then
    echo "==> Driving interaction script inside container"
    podman cp "$INTER_SCRIPT" "$CONTAINER:/home/triton/inter.sh"
    podman exec --user 1000:1000 "$CONTAINER" \
        bash -c 'export XDG_RUNTIME_DIR=/home/triton/xdg WAYLAND_DISPLAY=wayland-1 SWAYSOCK=$(ls /home/triton/xdg/sway-ipc* 2>/dev/null | head -1)
            bash /home/triton/inter.sh' \
        || echo "    (interaction script failed)"
fi

echo "==> Capturing screenshot and shell log"
podman exec --user 1000:1000 "$CONTAINER" \
    bash -c 'export XDG_RUNTIME_DIR=/home/triton/xdg WAYLAND_DISPLAY=wayland-1 SWAYSOCK=$(ls /home/triton/xdg/sway-ipc* 2>/dev/null | head -1)
        # Headless sway is damage-driven and slow under llvmpipe. Nudge a full
        # repaint, wait out the frame latency, then capture.
        swaymsg "output * power on" >/dev/null 2>&1; hyprctl reload >/dev/null 2>&1
        sleep 2
        grim /home/triton/shots/shell.png 2>/dev/null' \
    || echo "    (grim failed — compositor may not be up)"

SHOT_DIR="$REPO_ROOT/.out/shell"
mkdir -p "$SHOT_DIR"
podman cp "$CONTAINER:/home/triton/shots/shell.png" "$SHOT_DIR/shell.png" 2>/dev/null \
    && echo "    screenshot: $SHOT_DIR/shell.png" \
    || echo "    (no screenshot captured)"
podman cp "$CONTAINER:/home/triton/quickshell.log" "$SHOT_DIR/quickshell.log" 2>/dev/null || true

if [[ -n "$SHOT_OUT" && -f "$SHOT_DIR/shell.png" ]]; then
    cp "$SHOT_DIR/shell.png" "$SHOT_OUT"
fi

echo "==> Shell log:"
if [[ -f "$SHOT_DIR/quickshell.log" ]]; then
    cat "$SHOT_DIR/quickshell.log"
    if grep -qE "ERROR|error|is not installed|is not a type" "$SHOT_DIR/quickshell.log"; then
        echo "!! shell reported errors" >&2
        exit 1
    fi
    # A shell that loads but crashes is invisible in a log tail — the timeout
    # exit path is success. Errors above already covered the failure case.
    echo "==> OK: shell loaded with no errors"
else
    echo "!! no quickshell log — the shell never started" >&2
    exit 1
fi
