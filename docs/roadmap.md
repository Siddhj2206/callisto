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

- [ ] Dedicated lock-screen PAM stack (#8, #22, M3)
- [ ] Clipboard via `cliphist` as a user service, skipping password-manager copies (#9, M4)
- [ ] Atomic settings store writes (#4, M6)
- [ ] Don't drop a change made while the engine is running (#3; M9 replaces this)
- [ ] Display scale can return to 1.0 (#6)
- [ ] Test Bluetooth and keyring storage on real hardware
- [ ] Boot menu: Callisto branding and a timeout (it says Debian and waits for Enter)

## 3. Board comparison and design system

- [ ] Render each surface state headless and diff it against the board (`compare-board.sh`)
- [ ] Fix the veil values in `generate-theme.py`; generate type ramp, materials and light palette
- [ ] Literal lint: warn on old directories, fail on new ones
- [ ] Component gallery (dark, light, reduce motion)
- [ ] Compact desktop size scale (bar height, controls, rows, padding), mocked up and approved before building
- [ ] Foundations, including spring motion and `Presence`
- [ ] Primitives (set A)

## 4. Platform architecture

- [ ] Keybinds through `GlobalShortcut`; media keys without `uwsm app` (#7, M7)
- [ ] Shell as a systemd user unit, with lock restore (M8)
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

- [ ] OSD
- [ ] Bar (#13), with the new defaults: hidden with edge reveal, 120 ms
- [ ] Launcher (#12)
- [ ] Quick Settings
- [ ] Notifications
- [ ] Power
- [ ] Clipboard
- [ ] Window switcher and Overview (#10)
- [ ] Wallpaper picker (#15)
- [ ] Lock and Greeter (#10, #14)
- [ ] Screenshot (#10)
- [ ] Settings app (#11)
- [ ] Light mode and contrast pass

## 6. Release

- [ ] Flatpak accent portal and color override (M16)
- [ ] Greeter on greetd and Calamares installer (M17)
- [ ] Plymouth and fwupd (M18)
- [ ] In-shell polkit agent (M19, without fingerprint)
- [ ] Sunrise-based auto dark mode and night light (M20)
- [ ] Repo hygiene: untrack `.isotest/`, fix `.gitignore`, update `README.md` (#18)
- [ ] CI: lint, `qmllint`, ISO build, QEMU smoke test
