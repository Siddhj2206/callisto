# Callisto roadmap

The tracker for what's left. Tick items when they're done, and say how they
were checked.

- Why: [`audit.md`](audit.md) (defect numbers below refer to it)
- Platform detail: [`research/platform-stack.md`](research/platform-stack.md) (`M1`–`M20` are its migration list)
- Shell spec: [`design/component-system.md`](design/component-system.md) and [`design/surfaces/`](design/surfaces/)
- Design spec: [`../references/`](../references/)

The original 6-day execution plan that lived here is in git history.

## Constraints

- Debian trixie plus trixie-backports, built with `live-build`. Packaged
  Hyprland and Quickshell, not compiled from source.
- The boards in `references/` are the design spec. Don't invent tokens.
- Shell code takes every size, color, radius, font and duration from the theme.

## Decisions

| Topic | Decision |
|---|---|
| Platform | All in on Hyprland, systemd and Flatpak |
| Shell | Rebuild on a component library, shadcn-style. Keep `services/` |
| `references/dux-shell` | Patterns only (popouts, animation). Triton keeps its own look |
| Flatpak colors | Apps get the full wallpaper palette (read-only override), on by default, with a toggle |
| Glass | Shows the wallpaper only (xray on); the launcher may be the exception |
| Light mode | Lock, greeter, power, overview and screenshot are always dark; the rest follows light/dark |
| Blur | Every translucent surface is blurred; no per-material matching with the boards |
| Springs | Own spring component, tested on Quickshell 0.3.0, tuned by eye |
| Shapes | Panel radius in three sizes (28/32/36); "on" tile is a rounded square |
| Bar defaults | Hidden with edge reveal, 120 ms delay |
| Density | Desktop, not touch: deflate the bar and other chrome. Board sizes (56 px bar included) are too big |
| File manager | Nautilus from Debian |
| App store | Bazaar for now |
| Kernel and graphics | Use backports for newer hardware |
| Fingerprint | Not in the first release |
| Updates | apt; image-based updates later if at all |
| Installer | Calamares |

## 1. Broken basics

Branch `fix/broken-basics`. Tested on a booted ISO in QEMU on 2026-11-27.

- [x] hypridle is restarted instead of HUP'd, which killed it (#19, M1). In QEMU: still active, new PID after a setting change.
- [x] `bluez` added (#20, M5). In QEMU: service enabled and `bluetoothctl` present. The VM has no adapter, so **pairing is untested**.
- [x] Secret portal points at gnome-keyring (#21, M2). In QEMU: the portal exposes `Secret`. Storing a secret is untested.
- [x] Pinned bar is a Mica strip that reserves its height (#1). In QEMU: 56 px reserved, new windows start below.
- [x] Settings window floats (#2). In QEMU. Default height lowered to 700 to fit an 800 px screen; that one line was hot-swapped into the VM and is not in the built ISO.
- [x] Fingerprint hint removed from the lock screen (#8, part). In QEMU: lock and unlock work.

## 2. Remaining correctness fixes

- [x] Dedicated lock-screen PAM stack, `callisto-lock`, falling back to `login` if the file is missing (#8, #22, M3). In QEMU. Fingerprint is not in the first release
- [x] Clipboard via `cliphist` as a user service, skipping password-manager copies (#9, M4). Checked in a VM with the package and unit installed by hand; **not yet in a built ISO**
- [ ] Atomic settings store writes (#4, M6)
- [ ] Don't drop a change made while the engine is running (#3; M9 replaces this)
- [ ] Display scale can return to 1.0 (#6)
- [ ] Test Bluetooth and keyring storage on real hardware
- [ ] Boot menu: Callisto branding and a timeout (it says Debian and waits for Enter)

## 3. Component system

Built as surfaces need it: a component is added when a surface uses it, not
before. The old shell code is a reference only. Rules and file layout are in
[`design/component-system.md`](design/component-system.md) §0a.

- [x] Generated tokens with a desktop size scale; board sizes kept for comparison (`CALLISTO_DENSITY=board`)
- [x] Veil values in `generate-theme.py` fixed; dark and light schemes generated
- [x] Motion: `Spring`, `Fade`, `Presence`. Spring checked on Quickshell 0.3.0: 9.45% overshoot (9.5% expected)
- [x] Foundations and the primitives the bar and OSD use
- [x] Component gallery, dark and light (`shell/triton/gallery.qml`, panels in `gallery-panels.qml`)
- [x] Drop-down panel (`Popover`), tile, slider, switch, button, list row, text field
- [x] Literal lint for `primitives/`, `patterns/`, `surfaces/` (`scripts/lint-literals.py`; run by hand until CI exists)
- [x] Desktop sizes approved "for now" (gallery)
- [ ] Floating shadows (needs `qml6-module-qtquick-effects` and a higher `ignore_alpha`)
- [ ] Screenshot-versus-board diff script (so far compared by eye)

## 4. Platform architecture

- [ ] Keybinds through `GlobalShortcut`; media keys without `uwsm app` (#7, M7)
- [x] Shell as `callisto-shell.service`, with lock restore (M8). In QEMU: killed while locked, it restarts and locks again. **Not yet in a built ISO**
- [ ] `callisto-settingsd` replaces `callisto-apply` (#3, #4, #5, M9)
- [ ] Power profile set by the shell (M10)
- [ ] Simpler start-up (#25 part, M11)
- [ ] Settings as its own process (#16, M12)
- [ ] Flatpak cleanup: Debian Nautilus, pinned languages, Bazaar (#23, #24, M13)
- [ ] Boot trim, zram, oomd (#25, M14)
- [ ] Hyprland GPU defaults and per-surface layer rules (M15)
- [ ] Backports kernel and Mesa

## 5. Rebuild the surfaces

One at a time, each checked against its board and recorded for motion. The
definition of done is in `component-system.md` §7.

- [x] OSD: volume, mute, brightness, microphone. Volume and mute checked on a booted ISO in QEMU
  - [ ] Layout, workspace, track and low-battery variants (no producers yet)
- [x] Bar (#13): edge reveal by default, pinned, window title. Checked in QEMU, which also showed that clicking a workspace had never worked on Hyprland 0.55
  - [ ] Media pill, recording and mic chips, workspace preview, tray
  - [ ] Fade a long window title instead of cutting it; suppress reveal over fullscreen
  - [ ] Window title appears only after the first focus change if the shell restarts
- [x] Launcher (#12): ranked by match and habit, open windows, commands, arithmetic, app actions; apps start in their own systemd scope. Checked in QEMU
  - [ ] File search (`/`) and reveal in files
  - [ ] Spring out of the bar's wave button (it drops from the top)
- [x] Quick Settings: main, Wi-Fi, Bluetooth and Sound pages. Clicks, slider, drill-in, Esc and click-outside checked in QEMU on Hyprland
  - [ ] Try Wi-Fi joining, Bluetooth and brightness on real hardware (the VM has none)
  - [ ] Arrow-key grid navigation between tiles (Tab works)
  - [ ] Battery line, media card
- [x] Notifications: toasts and center. Timeout, hover pause, overflow, replace, withdraw, actions, inline reply and Do Not Disturb checked in QEMU, with the replies seen on D-Bus
  - [ ] Wavy progress, call and screenshot card kinds
  - [ ] Center keyboard navigation (Tab and Esc work)
- [x] Power: one connected group, countdown before log out, restart and shut down. In QEMU: keys, cancel, inhibitor note and refusal, lock and unlock, shut down
  - [ ] Unsaved-work dialog and pending-updates note (no data source yet)
- [x] Clipboard: search, filters, preview, pin, delete, clear, paste. Checked in QEMU, pasting into foot and Firefox
  - [ ] Retention settings; grouping by day
- [ ] Window switcher and Overview (#10)
- [ ] Wallpaper picker (#15)
- [x] Lock (#10, #14): pure view and host, shared backdrop, login card and password field. In QEMU: wrong and right password, restart while locked, with and without the blur module. Open: media pill, caps-lock chip, unlocking state, a look on real multi-monitor hardware
- [x] Greeter: greetd running the shell's `greeter.qml`, tuigreet behind it. In QEMU: login, back after logout, wrong and right password, shut down, fallback. **Not yet in a built ISO**. Open: other users by name, keyboard layout and session pickers, multi-monitor
- [ ] Screenshot (#10)
- [ ] Settings app (#11)
- [ ] Light mode and contrast pass
- [ ] **Check blur on every surface.** ISO rebuilt at `fb763d0`; blur is on and looks right behind the launcher and power menu. Bar, OSD, quick settings, toasts and the center still need a look over a busy background

## 6. Release

- [ ] Flatpak accent portal and color override (M16)
- [ ] Greeter on greetd and Calamares installer (M17)
- [ ] Plymouth and fwupd (M18)
- [ ] In-shell polkit agent (M19, without fingerprint)
- [ ] Sunrise-based auto dark mode and night light (M20)
- [ ] Repo hygiene: untrack `.isotest/`, fix `.gitignore`, update `README.md` (#18)
- [ ] CI: lint, `qmllint`, ISO build, QEMU smoke test
