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
# project, not a flat directory of files. Fonts are copied into the tree first
# (gitignored there; design/fonts/ is the source of truth) so the shell can
# FontLoader them relative to shell.qml in dev and installed layouts alike.
mkdir -p "$REPO_ROOT/shell/triton/fonts"
cp "$REPO_ROOT"/design/fonts/*.ttf "$REPO_ROOT/shell/triton/fonts/" 2>/dev/null || true
qml_files=("$REPO_ROOT"/shell/triton/**/*.qml)
if (( ${#qml_files[@]} > 0 )); then
    cp -r "$REPO_ROOT/shell/triton/." "$SKEL/quickshell/triton/"
    find "$SKEL/quickshell/triton" -name "*.qml" -exec chmod 0644 {} +
    # Fonts also install system-wide so non-shell apps (fuzzel, foot, GTK)
    # see the same typography.
    mkdir -p "$INCLUDES/usr/share/fonts/triton"
    cp "$REPO_ROOT"/design/fonts/*.ttf "$INCLUDES/usr/share/fonts/triton/"
else
    echo "    (no QML files yet — shell/triton is empty)"
fi

# --- Desktop configuration ---------------------------------------------------
install -m 0644 "$REPO_ROOT/configs/hypr/hyprland.lua" "$SKEL/hypr/hyprland.lua" 2>/dev/null \
    || echo "    (no hyprland.lua yet)"
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

# Seed the compiled outputs so first-boot targets that fail hard on missing
# includes (foot's include directive) find real files. These are the same
# bytes `callisto-apply` would emit from defaults; the engine rewrites them
# at first boot anyway.
python3 "$REPO_ROOT/scripts/engine/callisto-apply" --help >/dev/null 2>&1 || true

echo "==> includes.chroot is up to date"
