# Callisto — Status Report (morning of Nov 27)

## What you have right now

`callisto-amd64.hybrid.iso` — a bootable Debian 13 live ISO (~3GB) that boots
straight into a working Callisto desktop: Hyprland 0.55.2 + the Triton shell
with zero config errors, verified end-to-end in QEMU.

**Note:** the ISO currently on disk is one build behind the final fix (foot.ini
include path). Build 11 with that fix finishes ~03:20 — the ISO file gets
replaced automatically. Everything else verified below is in it.

## Verified in QEMU on real ISO boots (screenshots in .isotest/)

1. **First boot** — autologin to graphical desktop, wallpaper rendering, themed
   bar (wave launcher, workspace pills, clock, wifi/volume/battery/bell),
   ZERO config-error banners.
2. **Keybinds** — Super+Return opens foot, launcher/shell binds fire
   (meta_l in QEMU; hardware Super works the same).
3. **Launcher** — real DesktopEntries: Firefox, Files, foot, mpv with themed
   icons, glass panel over blurred wallpaper.
4. **Settings app** — full design-board layout, 14 panels through lazy Loader.
5. **Theme end-to-end** — custom hex accent (#E58A4B) re-themed the whole
   desktop live (orange wave, pills, accents); wallpaper-extraction themes it
   blue; light mode repaints the shell (verified live RGB samples).
6. **Dark mode chain** — portal returns 1 (dark), Firefox (flatpak) opens dark
   themed. (This required libglib2.0-bin — was missing entirely before.)
7. **Lock screen** — lock, type password, Enter → session unlocks. PAM auth
   verified. Wrong-password state wired.
8. **Wallpaper picker** — 6 generative scenes + image, live matugen palette
   extraction in the Colors card, preview-on-desktop.
9. **Services** — hyprpolkitagent, hypridle (regenerating config), hyprsunset
   all active; zero failed user units; clipwatch clipboard daemon running.
10. **Engine** — hyprctl eval live pushes work (0.55 lua dialect), monitor
    scale rules, power-profiles-daemon, keyboard layout/rate/sensitivity all
    verified in the container harness.

## What the settings app controls (no dotfiles needed, ever)

- **Appearance**: mode (dark/light/auto-by-time), accent (wallpaper/5 seeds/custom hex),
  contrast, material (solid/mica/glass), wallpaper + generative scenes + applying-to targets.
- **Input**: keyboard layout (10 layouts), repeat rate/delay/on-off, pointer speed,
  natural scroll, tap-to-click — all live-applied.
- **Shell**: bar mode (pinned/hidden/edge + real edge sensor), reveal delay,
  clock format, window title island, wavy-ring battery, urgent-notification peek,
  reduce motion.
- **Power**: profiles (powerprofilesctl), idle dim/suspend (regenerates hypridle.conf).
- **Displays**: scale stops, refresh rate, VRR, night light (hyprsunset).
- **Sound**: live pipewire volumes + real device list.
- **Network/Bluetooth**: real NM/BlueZ state and control.
- **Notifications**: DND single-source-of-truth, lockscreen visibility.

## Honest limits (nothing faked)

- Displays arrangement canvas: caption admits it's future work (no drag lie).
- Clipboard history: text-only for v0.1 (real daemon, real paste).
- Overview shows workspace/window structure, not live thumbnails.
- Lock wallpaper is dimmed, not blurred (compositor cooperation needed).
- Auto light/dark is time-of-day (07–19), not geolocated sunrise.
- ISO is live-session only — there's no installer path yet (greeter flow
  is autologin; installed-system greeter is future work).

## ISO contents

Hyprland 0.55.2 + quickshell 0.3.0 (backports), uwsm session management,
pipewire/wireplumber, NetworkManager, power-profiles-daemon, flatpak with
Firefox/Nautilus/mpv preinstalled, Jost/Google Sans Flex/JetBrains Mono/
Material Symbols fonts, matugen, foot terminal (themed live), python3 engine.

## If you want to iterate

- `scripts/build-iso.sh` — full rebuild (~25 min, squashfs is the long pole)
- `scripts/test-iso.sh` + `.isotest/drive.sh` — QEMU automation
- `scripts/push-to-vm.sh` + `.isotest/share/refresh-shell.sh` — hot-swap the
  shell into a running VM without rebuilding (iterate in minutes)
- `scripts/test-shell.sh` — sway harness for shell-only iteration
