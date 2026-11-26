#!/usr/bin/env bash
# entrypoint-shelltest.sh — inside the callisto-shelltest container.
#
# Boots sway, then runs the Triton shell against it. Two modes:
#
#   headless (default): sway uses the wlroots headless backend — no host
#     window, no host Wayland socket, fully hermetic. Verification happens
#     programmatically: the shell's startup is logged, and screenshots come
#     from grim through the wlr-screencopy protocol.
#
#   nested (SWAY_NESTED=1): sway connects outward through an inherited host
#     socket and appears as a window — for when you want to look at it live.
#
# sway is the stand-in compositor: same layer-shell protocol as Hyprland,
# trivially nestable, no seat/DRM requirements. Hyprland-specific IPC is
# verified separately in QEMU against the real ISO.

set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/home/triton/xdg}"
export XDG_SESSION_TYPE=wayland
export WLR_RENDERER_ALLOW_SOFTWARE=1
export WLR_BACKENDS="${WLR_BACKENDS:-headless}"

# In headless mode the host WAYLAND_DISPLAY must not leak through: wlroots
# probes backends in order, and a present-but-dead wayland socket name makes
# it pick the wayland backend over headless and fail outright.
if [[ "$WLR_BACKENDS" == "headless" ]]; then
    unset WAYLAND_DISPLAY
fi

mkdir -p "$XDG_RUNTIME_DIR" /home/triton/.cache /home/triton/shots

# Give the virtual output usable geometry; the headless backend defaults
# small. Config is regenerated every boot — never edited by hand.
# QS_ENTRY selects the entry point: shell.qml production, devshell.qml harness.
QS_ENTRY="${QS_ENTRY:-shell.qml}"
# Seed user tokens before the shell boots — the production order
# (callisto-apply runs at session start, before qs). Mirrors the real
# boot flow so live-watch behavior is exercised in the harness.
if [[ -n "${SEED_TOKENS:-}" ]]; then
    mkdir -p /home/triton/.config/callisto
    cp "$SEED_TOKENS" /home/triton/.config/callisto/tokens.json
fi

# COMPOSITOR=hyprland exercises the real integration — workspace IPC, layer
# rules, the exact runtime the ISO ships. sway remains the default because it
# is faster under llvmpipe.
if [[ "${COMPOSITOR:-sway}" == "hyprland" ]]; then
    cat > /home/triton/hyprland.conf <<HYEOF
monitor = HEADLESS-1, 1920x1080, 0x0, 1
exec-once = env QT_QPA_PLATFORM=wayland qs -p /triton/${QS_ENTRY} > /home/triton/quickshell.log 2>&1
animations { enabled = false }
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}
HYEOF
    exec Hyprland -c /home/triton/hyprland.conf
fi

cat > /home/triton/sway.conf <<EOF
output HEADLESS-1 resolution 1920x1080 position 0,0
output * bg #111318 solid_color
default_border none
exec env QT_QPA_PLATFORM=wayland qs -p /triton/${QS_ENTRY} > /home/triton/quickshell.log 2>&1
EOF

exec sway -c /home/triton/sway.conf
