#!/usr/bin/env bash
# test-shell.sh — run the Triton shell in a nested sway container.
#
# Iteration loop for shell/ development without the ISO, a VM, or touching
# your real session:
#   1. edit QML in shell/triton/
#   2. ./scripts/test-shell.sh   (or make test-shell)
#   3. a window appears on your desktop: nested sway running the shell
#   4. close it / Ctrl-C, edit, repeat
#
# How it works: the container inherits only your Wayland socket, so sway
# starts in nested mode as a client window of your session. The shell sources
# and fonts are bind-mounted read-only — no image rebuild for QML changes.
# SELinux note: the socket mount needs :z relabeling on Fedora; volume mounts
# of the repo use :z as well.
#
# Requires: rootless podman, host Wayland session. No GPU needed — software
# rendering.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="callisto-shelltest"

: "${XDG_RUNTIME_DIR:?not a graphical session}"
: "${WAYLAND_DISPLAY:?not a Wayland session}"

# Fonts must exist inside shell/triton/fonts for the shell to load them.
mkdir -p "$REPO_ROOT/shell/triton/fonts"
cp "$REPO_ROOT"/design/fonts/*.ttf "$REPO_ROOT/shell/triton/fonts/" 2>/dev/null || true

if ! podman image exists "$IMAGE"; then
    echo "==> Building $IMAGE (first run only)"
    podman build -f "$REPO_ROOT/Dockerfile.shelltest" -t "$IMAGE" "$REPO_ROOT"
fi

# The host socket is mounted at an absolute path OUTSIDE the runtime dir:
# WAYLAND_DISPLAY accepts absolute paths, and this avoids the tmpfs-over-mount
# shadowing problem entirely.
exec podman run --rm -it \
    --name callisto-shelltest \
    --userns=keep-id \
    --user 1000:1000 \
    -e WAYLAND_DISPLAY="/wl/socket" \
    -e XDG_RUNTIME_DIR=/home/triton/xdg \
    --tmpfs /home/triton/xdg:rw,exec,mode=0700,U \
    -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/wl/socket:z" \
    -v "$REPO_ROOT/shell/triton:/triton:ro,z" \
    "$IMAGE"
