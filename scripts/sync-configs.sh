#!/usr/bin/env bash
# sync-configs.sh — stage the repository into live-build's includes.chroot.
#
# That tree is overlaid verbatim onto the image. It is generated: rebuilt from
# nothing on every run, so a file removed here never lingers in a build.
# Files for every new account go under etc/skel, everything else to its real
# path, so that updates reach accounts that already exist.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$REPO/live-build/config/includes.chroot"

# put MODE SOURCE TARGET: SOURCE relative to the repository, TARGET to the image.
put() {
    install -D -m "$1" "$REPO/$2" "$ROOT/$3"
}

echo "==> Staging into ${ROOT#"$REPO"/}"
rm -rf "$ROOT"

# --- Shell -------------------------------------------------------------------
# One Quickshell project, copied whole minus the developer galleries.
mkdir -p "$REPO/shell/triton/fonts" "$ROOT/etc/xdg/quickshell/triton"
cp "$REPO"/design/fonts/*.ttf "$REPO/shell/triton/fonts/"
cp -r "$REPO/shell/triton/." "$ROOT/etc/xdg/quickshell/triton/"
rm -r "$ROOT/etc/xdg/quickshell/triton/gallery" "$ROOT/etc/xdg/quickshell/triton/gallery.qml"
find "$ROOT/etc/xdg/quickshell" -name '*.qml' -exec chmod 0644 {} +
# The fonts are also installed system-wide, for every other program.
mkdir -p "$ROOT/usr/share/fonts/triton"
cp "$REPO"/design/fonts/*.ttf "$ROOT/usr/share/fonts/triton/"

# --- Programs ----------------------------------------------------------------
# callisto-settingsd loads callisto-apply from beside itself.
mkdir -p "$ROOT/usr/local/bin"
install -m 0755 "$REPO"/bin/* "$ROOT/usr/local/bin/"
for unit in callisto-shell.service callisto-settingsd.socket callisto-settingsd.service callisto-clipboard.service; do
    put 0644 "configs/systemd/user/$unit" "usr/lib/systemd/user/$unit"
done
put 0644 configs/applications/org.callisto.Settings.desktop usr/share/applications/org.callisto.Settings.desktop

# --- Data the system reads ---------------------------------------------------
# /usr/share/callisto holds shipped defaults. Nothing writes there after
# install, so an update never overwrites what a user chose.
put 0644 design/tokens.json usr/share/callisto/tokens.json
put 0644 configs/callisto/default-settings.json usr/share/callisto/default-settings.json
put 0644 live-build/config/package-lists/callisto.flatpaks.txt usr/share/callisto/flatpaks.txt
put 0644 design/wallpaper.jpg usr/share/backgrounds/callisto/wallpaper.jpg

# The logo: the icon os-release names, at every size.
for size in 16 24 32 48 64 128 256 512; do
    put 0644 "design/logo/png/callisto-logo-$size.png" "usr/share/icons/hicolor/${size}x${size}/apps/callisto-logo.png"
done
put 0644 design/logo/png/callisto-logo-256.png usr/share/pixmaps/callisto-logo.png

# --- Session -----------------------------------------------------------------
put 0644 configs/hypr/hyprland.lua usr/share/callisto/hypr/hyprland.lua
put 0644 configs/hypr/user-stub.lua etc/skel/.config/hypr/hyprland.lua
put 0644 configs/session/uwsm-env etc/xdg/uwsm/env
put 0644 configs/session/uwsm-env-hyprland etc/xdg/uwsm/env-hyprland
put 0644 configs/session/mimeapps.list etc/xdg/mimeapps.list
# /etc/xdg overrides the portal file Hyprland ships.
put 0644 configs/portal/hyprland-portals.conf etc/xdg/xdg-desktop-portal/hyprland-portals.conf

# foot fails hard on a missing include, so its config ships with the account.
put 0644 configs/foot/foot.ini etc/skel/.config/foot/foot.ini
put 0644 configs/gtk/settings.ini etc/skel/.config/gtk-3.0/settings.ini
put 0644 configs/gtk/settings.ini etc/skel/.config/gtk-4.0/settings.ini
put 0644 configs/fastfetch/config.jsonc etc/xdg/fastfetch/config.jsonc
put 0644 configs/fastfetch/logo.txt usr/share/callisto/fastfetch-logo.txt

# --- Login, lock and boot ----------------------------------------------------
put 0644 configs/greeter/greetd.toml etc/greetd/config.toml
put 0644 configs/greeter/hyprland.lua usr/share/callisto/greeter/hyprland.lua
put 0644 configs/greeter/tmpfiles.conf usr/lib/tmpfiles.d/callisto-greeter.conf
put 0644 configs/pam/greetd etc/pam.d/greetd
put 0644 configs/pam/callisto-lock etc/pam.d/callisto-lock
put 0644 configs/boot/zram-generator.conf etc/systemd/zram-generator.conf
put 0644 configs/boot/grub-callisto.cfg etc/default/grub.d/callisto.cfg

# --- Installer ---------------------------------------------------------------
INSTALLER="$REPO/configs/installer"
mkdir -p "$ROOT/etc/calamares"
cp -r "$INSTALLER/settings.conf" "$INSTALLER/modules" "$INSTALLER/branding" "$ROOT/etc/calamares/"
put 0755 configs/installer/callisto-install usr/local/bin/callisto-install
put 0755 configs/installer/install-prepare usr/lib/callisto/install-prepare
put 0755 configs/installer/install-bootloader usr/lib/callisto/install-bootloader
# Live session only; listed in live/live-only so the installed system drops them.
put 0755 configs/installer/live/setxkbmap usr/local/bin/setxkbmap
put 0755 configs/installer/live/callisto-install-hint usr/lib/callisto/install-hint
put 0644 configs/installer/live/live-only usr/lib/callisto/live-only
put 0644 configs/installer/live/org.callisto.Install.desktop usr/share/applications/org.callisto.Install.desktop
put 0644 configs/installer/live/callisto-install-hint.service usr/lib/systemd/user/callisto-install-hint.service
put 0440 configs/installer/live/callisto-live.sudoers etc/sudoers.d/callisto-live

echo "==> Done"
