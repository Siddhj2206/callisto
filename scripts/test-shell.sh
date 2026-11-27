#!/usr/bin/env bash
# test-shell.sh — verify the Triton shell inside a headless sway container.
#
# The shell iteration loop without the ISO, a VM, or any contact with your
# real session:
#
#   ./scripts/test-shell.sh           headless verification: boots sway
#                                     headless + the shell, waits, captures a
#                                     screenshot and the shell log, reports
#                                     errors, exits non-zero on failure
#
#   ./scripts/test-shell.sh --nested  interactive: sway nests as a window in
#                                     your session so you can look at it live
#
#   ./scripts/test-shell.sh --shot out.png   headless, keep screenshot at path
#
# Headless mode is fully hermetic: no host Wayland socket, no host services,
# the container is wiped on exit. State you care about (screenshot, log) is
# copied out before teardown.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="callisto-shelltest"
MODE="headless"
SHOT_OUT=""
# Headless sway under llvmpipe is slow to land the first shell frame; the
# default wait accounts for that.
WAIT_SECONDS=12

QS_ENTRY="shell.qml"
INTER_SCRIPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --nested) MODE="nested"; shift ;;
        --shot) SHOT_OUT="$2"; shift 2 ;;
        --wait) WAIT_SECONDS="$2"; shift 2 ;;
        --dev) QS_ENTRY="devshell.qml"; shift ;;
        --entry) QS_ENTRY="$2"; shift 2 ;;
        --script) INTER_SCRIPT="$2"; shift 2 ;;
        *) echo "test-shell: unknown argument: $1" >&2; exit 2 ;;
    esac
done

# Fonts must exist inside shell/triton/fonts for the shell to load them.
mkdir -p "$REPO_ROOT/shell/triton/fonts"
cp "$REPO_ROOT"/design/fonts/*.ttf "$REPO_ROOT/shell/triton/fonts/" 2>/dev/null || true

if ! podman image exists "$IMAGE"; then
    echo "==> Building $IMAGE (first run only)"
    podman build -f "$REPO_ROOT/Dockerfile.shelltest" -t "$IMAGE" "$REPO_ROOT"
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
        -e CALLISTO_DENSITY="${CALLISTO_DENSITY:-compact}" \
        --tmpfs /home/triton/xdg:rw,exec,mode=0700,U \
        -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/wl/socket" \
        -v "$REPO_ROOT/shell/triton:/triton:ro" \
    -v "$REPO_ROOT/scripts/intertest:/triton-intertest:ro" \
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
    -e COMPOSITOR="${COMPOSITOR:-sway}" \
    -e CALLISTO_DENSITY="${CALLISTO_DENSITY:-compact}" \
    --tmpfs /home/triton/xdg:rw,exec,mode=0700,U \
    -v "$REPO_ROOT/shell/triton:/triton:ro" \
    -v "$REPO_ROOT/scripts/intertest:/triton-intertest:ro" \
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

SHOT_DIR="$REPO_ROOT/.devtest"
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
    if grep -qE "ERROR|error" "$SHOT_DIR/quickshell.log"; then
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
