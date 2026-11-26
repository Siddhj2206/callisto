#!/usr/bin/env bash
# entrypoint-shelltest.sh — inside the callisto-shelltest container.
#
# Boots Hyprland nested (as a client of the inherited host Wayland session),
# then starts the Triton shell. Intended for fast iteration: kill the
# container, edit QML, restart.

set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland

# Software rendering: nested virgl through a container is fragile and not
# worth the debugging time — llvmpipe is fast enough for QML iteration.
export WLR_RENDERER_ALLOW_SOFTWARE=1

# Launch the shell once Hyprland is accepting IPC connections. The compositor
# takes a moment to create its socket even after the process starts.
(
    for _ in $(seq 1 50); do
        if hyprctl version >/dev/null 2>&1; then
            quickshell -c triton -p /triton &
            break
        fi
        sleep 0.2
    done
) &

# Hyprland with no real outputs runs nested automatically when WAYLAND_DISPLAY
# is set. This process is PID 1-ish; when it exits the container stops.
exec Hyprland --config /hyprland-test.conf
