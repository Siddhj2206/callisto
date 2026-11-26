#!/usr/bin/env bash
# test-shell.sh — run the Triton shell in a nested Hyprland container.
#
# Iteration loop for shell/ development without the ISO or a VM:
#   1. edit QML in shell/triton/
#   2. ./scripts/test-shell.sh   (or make test-shell)
#   3. compositor window appears on your desktop running the shell
#   4. close window / Ctrl-C, edit, repeat
#
# How it works: the container inherits the host's Wayland socket, so Hyprland
# starts in nested mode as a client window of your current session. The shell
# sources are bind-mounted read-only at /triton, so no image rebuild is ever
# needed for QML changes — only dependency changes rebuild the image.
#
# Requires: rootless podman (unlike the ISO builder, this harness needs no
# privileges — it only runs compositor processes), host Wayland session.
# GPU is not required — the harness uses software rendering for robustness.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="callisto-shelltest"

: "${XDG_RUNTIME_DIR:?not a graphical session}"
: "${WAYLAND_DISPLAY:?not a Wayland session}"

if ! podman image exists "$IMAGE"; then
    echo "==> Building $IMAGE (first run only)"
    podman build -f "$REPO_ROOT/Dockerfile.shelltest" -t "$IMAGE" "$REPO_ROOT"
fi

# The container must reach the host's user Wayland socket and XDG_RUNTIME_DIR
# layout. Hyprland creates its own socket inside; the nested backend connects
# back out through the inherited one. Rootless podman maps the container's
# root user onto the host user, so the socket stays accessible.
exec podman run --rm -it \
    --name callisto-shelltest \
    -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -v "$XDG_RUNTIME_DIR:/run/user/1000" \
    -v "$REPO_ROOT/shell/triton:/triton:ro,z" \
    -v "$REPO_ROOT/configs/hypr/hyprland-test.conf:/hyprland-test.conf:ro,z" \
    "$IMAGE"
