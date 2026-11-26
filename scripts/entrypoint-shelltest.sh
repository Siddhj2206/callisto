#!/usr/bin/env bash
# entrypoint-shelltest.sh — inside the callisto-shelltest container.
#
# Boots sway nested (as a client of the inherited host Wayland session), then
# starts the Triton shell against it. Iteration loop: kill the container,
# edit QML, restart — seconds per cycle.
#
# sway is the stand-in compositor: same layer-shell protocol as Hyprland,
# trivially nestable, no seat/DRM requirements. Hyprland-specific IPC is
# verified separately in QEMU against the real ISO.

set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/home/triton/xdg}"
export XDG_SESSION_TYPE=wayland
export WLR_RENDERER_ALLOW_SOFTWARE=1
export WLR_BACKENDS=wayland

mkdir -p "$XDG_RUNTIME_DIR" /home/triton/.cache

# Minimal sway config: floating-friendly, no wallpaper logic, exec the shell
# once the compositor is up.
cat > /home/triton/sway.conf <<'EOF'
output * bg #111318 solid_color
default_border none
bar none
exec qs -p /triton
EOF

# sway in a Wayland session nests automatically. SIGTERM propagation: the
# container stops when sway exits.
exec sway -c /home/triton/sway.conf
