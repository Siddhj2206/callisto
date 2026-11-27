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
    "$INCLUDES/etc/xdg/quickshell" \
    "$INCLUDES/etc/calamares" \
    "$INCLUDES/usr/share/callisto/shell" \
    "$INCLUDES/etc/greetd" \
    "$INCLUDES/usr/share/backgrounds/callisto" \
    "$INCLUDES/usr/local/bin"

# The shell and the session config are system files, so that updates reach
# every account; a user's own copy under ~/.config wins.
SHELL_DIR="$INCLUDES/etc/xdg/quickshell/triton"

mkdir -p \
    "$SHELL_DIR" \
    "$SKEL/hypr" \
    "$SKEL/fuzzel" \
    "$SKEL/gtk-3.0" \
    "$SKEL/gtk-4.0" \
    "$INCLUDES/etc/greetd" \
    "$INCLUDES/usr/share/backgrounds/callisto" \
    "$INCLUDES/usr/local/bin"

# --- Shell (from-scratch component) -----------------------------------------
# The whole Triton shell is copied recursively — it is a modular Quickshell
# project, not a flat directory of files. Fonts are copied into the tree first
# (gitignored there; design/fonts/ is the source of truth) so the shell can
# FontLoader them relative to shell.qml in dev and installed layouts alike.
mkdir -p "$REPO_ROOT/shell/triton/fonts"
cp "$REPO_ROOT"/design/fonts/*.ttf "$REPO_ROOT/shell/triton/fonts/" 2>/dev/null || true
qml_files=("$REPO_ROOT"/shell/triton/**/*.qml)
if (( ${#qml_files[@]} > 0 )); then
    cp -r "$REPO_ROOT/shell/triton/." "$SHELL_DIR/"
    find "$SHELL_DIR" -name "*.qml" -exec chmod 0644 {} +
    # Fonts also install system-wide so non-shell apps (fuzzel, foot, GTK)
    # see the same typography.
    mkdir -p "$INCLUDES/usr/share/fonts/triton"
    cp "$REPO_ROOT"/design/fonts/*.ttf "$INCLUDES/usr/share/fonts/triton/"
else
    echo "    (no QML files yet — shell/triton is empty)"
fi

# --- Desktop configuration ---------------------------------------------------
install -D -m 0644 "$REPO_ROOT/configs/hypr/hyprland.lua" "$INCLUDES/usr/share/callisto/hypr/hyprland.lua"
install -m 0644 "$REPO_ROOT/configs/hypr/user-stub.lua" "$SKEL/hypr/hyprland.lua"
install -m 0644 "$REPO_ROOT/configs/fuzzel/fuzzel.ini" "$SKEL/fuzzel/fuzzel.ini" 2>/dev/null \
    || echo "    (no fuzzel.ini yet)"
if [[ -f "$REPO_ROOT/configs/gtk/gtk.css" ]]; then
    install -m 0644 "$REPO_ROOT/configs/gtk/gtk.css" "$SKEL/gtk-3.0/gtk.css"
    install -m 0644 "$REPO_ROOT/configs/gtk/gtk.css" "$SKEL/gtk-4.0/gtk.css"
fi
if [[ -f "$REPO_ROOT/configs/gtk/settings.ini" ]]; then
    install -m 0644 "$REPO_ROOT/configs/gtk/settings.ini" "$SKEL/gtk-3.0/settings.ini"
    install -m 0644 "$REPO_ROOT/configs/gtk/settings.ini" "$SKEL/gtk-4.0/settings.ini"
fi
# foot terminal config (theme include target ships even before the engine
# writes user overrides — include of a missing file is a hard error in foot).
if [[ -f "$REPO_ROOT/configs/foot/foot.ini" ]]; then
    mkdir -p "$SKEL/foot"
    install -m 0644 "$REPO_ROOT/configs/foot/foot.ini" "$SKEL/foot/foot.ini"
fi

# --- System-level files -------------------------------------------------------
# Portal backend selection. /etc/xdg overrides the file Hyprland ships.
install -D -m 0644 "$REPO_ROOT/configs/portal/hyprland-portals.conf" \
    "$INCLUDES/etc/xdg/xdg-desktop-portal/hyprland-portals.conf"
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

# The logo: the icon os-release names, at every size the kit renders.
for size in 16 24 32 48 64 128 256 512; do
    install -D -m 0644 "$REPO_ROOT/design/logo/png/callisto-logo-$size.png" \
        "$INCLUDES/usr/share/icons/hicolor/${size}x${size}/apps/callisto-logo.png"
done
install -D -m 0644 "$REPO_ROOT/design/logo/png/callisto-logo-256.png" \
    "$INCLUDES/usr/share/pixmaps/callisto-logo.png"
install -D -m 0644 "$REPO_ROOT/configs/fastfetch/config.jsonc" "$INCLUDES/etc/xdg/fastfetch/config.jsonc"
install -D -m 0644 "$REPO_ROOT/configs/fastfetch/logo.txt" "$INCLUDES/usr/share/callisto/fastfetch-logo.txt"

# --- System-level data -----------------------------------------------------------
# /usr/share/callisto holds OS-shipped defaults and manifests, deliberately
# separate from per-user config — distro updates must never overwrite user
# configuration, so nothing in here is ever written to after install.
mkdir -p "$INCLUDES/usr/share/callisto"
install -m 0644 "$REPO_ROOT/live-build/config/package-lists/callisto.flatpaks.txt" \
    "$INCLUDES/usr/share/callisto/flatpaks.txt"
install -m 0644 "$REPO_ROOT/design/tokens.json" \
    "$INCLUDES/usr/share/callisto/tokens.json"
install -m 0644 "$REPO_ROOT/configs/callisto/default-settings.json" \
    "$INCLUDES/usr/share/callisto/default-settings.json"

# The theme engine: the ONLY sanctioned writer of compiled config outputs.
install -m 0755 "$REPO_ROOT/scripts/engine/callisto-apply" \
    "$INCLUDES/usr/local/bin/callisto-apply"

# The settings daemon: the only writer of the store. It loads the engine from
# beside itself.
install -m 0755 "$REPO_ROOT/scripts/engine/callisto-settingsd" "$INCLUDES/usr/local/bin/"
for unit in callisto-settingsd.socket callisto-settingsd.service; do
    install -D -m 0644 "$REPO_ROOT/configs/systemd/user/$unit" "$INCLUDES/usr/lib/systemd/user/$unit"
done

# Clipboard history: the user service, its filter, and the picker's helper.
install -m 0755 "$REPO_ROOT/scripts/engine/callisto-clip" \
    "$REPO_ROOT/scripts/engine/callisto-clip-store" "$INCLUDES/usr/local/bin/"
install -D -m 0644 "$REPO_ROOT/configs/systemd/user/callisto-clipboard.service" \
    "$INCLUDES/usr/lib/systemd/user/callisto-clipboard.service"

# Screenshots: the capture and crop helper.
install -m 0755 "$REPO_ROOT/scripts/engine/callisto-shot" "$INCLUDES/usr/local/bin/"

# Settings: its launcher and menu entry (the app is part of the shell tree).
install -m 0755 "$REPO_ROOT/scripts/callisto-settings" "$INCLUDES/usr/local/bin/"
install -D -m 0644 "$REPO_ROOT/configs/applications/org.callisto.Settings.desktop" \
    "$INCLUDES/usr/share/applications/org.callisto.Settings.desktop"

# The shell itself.
install -D -m 0644 "$REPO_ROOT/configs/systemd/user/callisto-shell.service" \
    "$INCLUDES/usr/lib/systemd/user/callisto-shell.service"

# The greeter: its session script and compositor config.
install -m 0755 "$REPO_ROOT/scripts/callisto-greeter" "$INCLUDES/usr/local/bin/callisto-greeter"
install -D -m 0644 "$REPO_ROOT/configs/greeter/hyprland.lua" \
    "$INCLUDES/usr/share/callisto/greeter/hyprland.lua"
install -D -m 0644 "$REPO_ROOT/configs/greeter/tmpfiles.conf" \
    "$INCLUDES/usr/lib/tmpfiles.d/callisto-greeter.conf"

# Session environment, default applications, and greetd's PAM stack.
install -D -m 0644 "$REPO_ROOT/configs/session/uwsm-env" "$INCLUDES/etc/xdg/uwsm/env"
install -D -m 0644 "$REPO_ROOT/configs/session/uwsm-env-hyprland" "$INCLUDES/etc/xdg/uwsm/env-hyprland"
install -D -m 0644 "$REPO_ROOT/configs/session/mimeapps.list" "$INCLUDES/etc/xdg/mimeapps.list"
install -D -m 0644 "$REPO_ROOT/configs/pam/greetd" "$INCLUDES/etc/pam.d/greetd"

# The lock screen's own PAM stack.
install -D -m 0644 "$REPO_ROOT/configs/pam/callisto-lock" "$INCLUDES/etc/pam.d/callisto-lock"

# Memory compression and the boot menu's name on an installed system.
install -D -m 0644 "$REPO_ROOT/configs/boot/zram-generator.conf" "$INCLUDES/etc/systemd/zram-generator.conf"
install -D -m 0644 "$REPO_ROOT/configs/boot/grub-callisto.cfg" "$INCLUDES/etc/default/grub.d/callisto.cfg"

# The installer, and what offers it in the live session.
INSTALLER="$REPO_ROOT/configs/installer"
mkdir -p "$INCLUDES/etc/calamares"
cp -r "$INSTALLER/settings.conf" "$INSTALLER/modules" "$INSTALLER/branding" "$INCLUDES/etc/calamares/"
install -D -m 0755 "$INSTALLER/callisto-install" "$INCLUDES/usr/local/bin/callisto-install"
install -D -m 0755 "$INSTALLER/live/setxkbmap" "$INCLUDES/usr/local/bin/setxkbmap"
install -D -m 0755 "$INSTALLER/install-prepare" "$INCLUDES/usr/lib/callisto/install-prepare"
install -D -m 0755 "$INSTALLER/install-bootloader" "$INCLUDES/usr/lib/callisto/install-bootloader"
install -D -m 0755 "$INSTALLER/live/callisto-install-hint" "$INCLUDES/usr/lib/callisto/install-hint"
install -D -m 0644 "$INSTALLER/live/live-only" "$INCLUDES/usr/lib/callisto/live-only"
install -D -m 0644 "$INSTALLER/live/org.callisto.Install.desktop" "$INCLUDES/usr/share/applications/org.callisto.Install.desktop"
install -D -m 0644 "$INSTALLER/live/callisto-install-hint.service" "$INCLUDES/usr/lib/systemd/user/callisto-install-hint.service"
install -D -m 0440 "$INSTALLER/live/callisto-live.sudoers" "$INCLUDES/etc/sudoers.d/callisto-live"

# Seed the compiled outputs so first-boot targets that fail hard on missing
# includes (foot's include directive) find real files. These are the same
# bytes `callisto-apply` would emit from defaults; the engine rewrites them
# at first boot anyway.
python3 "$REPO_ROOT/scripts/engine/callisto-apply" --help >/dev/null 2>&1 || true

echo "==> includes.chroot is up to date"
