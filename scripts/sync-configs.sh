#!/usr/bin/env bash
# sync-configs.sh — copy shell/ and configs/ into live-build's includes.chroot.
#
# live-build's includes.chroot tree is overlaid verbatim onto the chroot before
# squashfs compression. Files that belong to every user (shell config, desktop
# theming) are staged under /etc/skel so the live user's home is provisioned
# at boot; system-level files go to their real paths.
#
# This script is idempotent: the staging tree is rebuilt from scratch on every
# invocation so removed files never linger in built images.

set -euo pipefail
shopt -s globstar nullglob

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDES="$REPO_ROOT/live-build/config/includes.chroot"

# live-boot user provisioning works via /etc/skel -> /home/user copy.
SKEL="$INCLUDES/etc/skel/.config"

echo "==> Syncing configuration into includes.chroot"

# Rebuild the managed subtrees from scratch; leave everything else untouched.
rm -rf \
    "$SKEL/quickshell/triton" \
    "$SKEL/hypr" \
    "$SKEL/fuzzel" \
    "$SKEL/foot" \
    "$SKEL/gtk-3.0" \
    "$SKEL/gtk-4.0" \
    "$SKEL/mako" \
    "$INCLUDES/etc/greetd" \
    "$INCLUDES/usr/share/backgrounds/callisto" \
    "$INCLUDES/usr/local/bin"

mkdir -p \
    "$SKEL/quickshell/triton" \
    "$SKEL/hypr" \
    "$SKEL/fuzzel" \
    "$SKEL/gtk-3.0" \
    "$SKEL/gtk-4.0" \
    "$INCLUDES/etc/greetd" \
    "$INCLUDES/usr/share/backgrounds/callisto" \
    "$INCLUDES/usr/local/bin"

# --- Shell (from-scratch component) -----------------------------------------
# The whole Triton shell is copied recursively — it is a modular Quickshell
# project, not a flat directory of files.
qml_files=("$REPO_ROOT"/shell/triton/**/*.qml)
if (( ${#qml_files[@]} > 0 )); then
    cp -r "$REPO_ROOT/shell/triton/." "$SKEL/quickshell/triton/"
    find "$SKEL/quickshell/triton" -name "*.qml" -exec chmod 0644 {} +
else
    echo "    (no QML files yet — shell/triton is empty)"
fi

# --- Desktop configuration ---------------------------------------------------
install -m 0644 "$REPO_ROOT/configs/hypr/hyprland.conf" "$SKEL/hypr/hyprland.conf" 2>/dev/null \
    || echo "    (no hyprland.conf yet)"
install -m 0644 "$REPO_ROOT/configs/fuzzel/fuzzel.ini" "$SKEL/fuzzel/fuzzel.ini" 2>/dev/null \
    || echo "    (no fuzzel.ini yet)"
if [[ -f "$REPO_ROOT/configs/gtk/gtk.css" ]]; then
    install -m 0644 "$REPO_ROOT/configs/gtk/gtk.css" "$SKEL/gtk-3.0/gtk.css"
    install -m 0644 "$REPO_ROOT/configs/gtk/gtk.css" "$SKEL/gtk-4.0/gtk.css"
fi

# --- System-level files -------------------------------------------------------
if [[ -f "$REPO_ROOT/configs/greetd/config.toml" ]]; then
    install -m 0644 "$REPO_ROOT/configs/greetd/config.toml" "$INCLUDES/etc/greetd/config.toml"
fi
if [[ -f "$REPO_ROOT/scripts/start-callisto" ]]; then
    install -m 0755 "$REPO_ROOT/scripts/start-callisto" "$INCLUDES/usr/local/bin/start-callisto"
fi

# --- Design assets ------------------------------------------------------------
install -m 0644 "$REPO_ROOT/design/wallpaper.jpg" \
    "$INCLUDES/usr/share/backgrounds/callisto/wallpaper.jpg" 2>/dev/null \
    || echo "    (no wallpaper yet)"

echo "==> includes.chroot is up to date"
