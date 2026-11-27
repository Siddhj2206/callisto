# Callisto audit — 2026-11-27

> A snapshot of the code before the rebuild. The paths and defects below are
> from that day; [`../roadmap.md`](../roadmap.md) tracks what has been fixed.

Scope: the Triton shell (`shell/triton/`), the settings engine
(`scripts/engine/`), the Hyprland config, the ISO build, and repo hygiene.

Method: read the code; compared the QEMU screenshots in `.isotest/` (Nov 26
builds) against renders of the design boards in `references/` (made with
`scripts/render-board.sh`). The current ISO was not booted for this audit.

## Summary

The plumbing is mostly real: services are wired, the engine writes real
configs, PAM unlock works. The presentation layer is where it falls down, and
it fails in a consistent pattern. The boards were copied pixel by pixel, but
the design system behind them (type scale, materials per mode, state layers,
motion) was never built. Each surface invents its own values, so they drift
apart, overflow, and pop in and out with no motion.

## Root causes

1. **Almost no motion.** There are 10 animations in the whole shell, all in
   switches, buttons, the wallpaper dock and the power menu.
   `configs/hypr/hyprland.lua:121` sets `no_anim` on every Quickshell layer.
   The spring tokens in `tokens.json` are generated into `Theme.qml` but never
   used; `bar/WorkspacePill.qml:27` explains why they were left out.
2. **No design-system layer.** Surface code contains about 171 font-size
   literals, 132 radius literals, 107 hex colors and about 300
   width/height/margin literals. `docs/shell-conventions.md` forbids all of
   these. There is no type scale and there are no shared surface components,
   so the same things (accent swatches, chips, keycaps, list rows, cards) are
   reimplemented per surface and don't match.
3. **Fixed board pixel sizes instead of layouts that adapt.**
   - Settings is a fixed 1100×760 item inside a window that gets tiled
     full-screen.
   - The launcher's top-hit title runs off its card.
   - The wallpaper picker's hint row overlaps the thumbnail labels, and the
     last thumbnail is cut off.
   - On the lock screen the auth card sits on top of the clock.
4. **Light mode was never designed.** The veils and materials are fixed
   white-alpha constants (`Theme.qml:59-63`). In light mode
   (`.isotest/b5-light4.png`) the workspace numbers and date are barely
   readable.
5. **"Verified" meant "loads without errors", not "matches the board."**
   Nothing compares screenshots against the boards, so drift was never caught.

## Defects (most severe first)

| # | Severity | Problem | Where |
|---|---|---|---|
| 1 | Critical | "Pinned" bar mode (the default) still draws floating islands with `exclusiveZone: 0`, so it covers app content (`FINAL-foot2.png`: the bar sits on the terminal prompt). The board says pinned is a full-width Mica strip that windows start below. | `shell/triton/bar/Bar.qml:116` |
| 2 | Critical | The float rule for Settings matches class `callisto-settings`, but the Quickshell `FloatingWindow` never sets that class. Settings is tiled full-screen under the bar, which covers its search box and title (`b4-settings.png`). | `configs/hypr/hyprland.lua:114`, `shell/triton/shell.qml:119` |
| 3 | High | A setting change can be dropped: if `callisto-apply` is still running when the last write finishes, that change is never applied. | `shell/triton/services/SettingsService.qml:87` |
| 4 | High | The settings store is written with a non-atomic `sh -c cat >` while the same file is being watched, so the shell can read a half-written file. | `shell/triton/services/SettingsService.qml` |
| 5 | High | Every setting change re-runs everything: `hyprctl eval`, hyprsunset, hypridle rewrite plus HUP, `powerprofilesctl`, and 4 `gsettings` calls. Changing the clock format re-sets the power profile. | `scripts/engine/callisto-apply:442` |
| 6 | High | Once display scale is changed, it can't be set back to 1.0: the engine skips scale whenever it equals 1.0. | `scripts/engine/callisto-apply:490` |
| 7 | High | Every keybind, and every volume-key repeat, starts a process through `uwsm app --`, and each one creates a systemd unit. This adds visible delay. | `configs/hypr/hyprland.lua:181` and the `qsipc` helper |
| 8 | Medium | The lock screen always says "or touch the fingerprint sensor" (there is no fprintd). It shows a battery icon in a VM. It uses the `login` PAM stack instead of a dedicated one. | `shell/triton/lock/LockScreen.qml:324`, `shell/triton/services/LockState.qml:49` |
| 9 | Medium | Clipboard history stores password-manager copies in plaintext; it doesn't check the sensitive-content hint. It starts a Python process on every copy. Pins are written by the shell while the daemon rewrites the same file. | `scripts/engine/callisto-clipwatch` |
| 10 | Medium | The screenshot tool, window switcher and greeter are fully built but never wired in. They only load in the `devshell-*.qml` test files. | `shell/triton/screenshot/`, `windowswitcher/`, `greeter/` |
| 11 | Medium | Accent seeds in Settings (Hull is navy, Rock is gray) contradict the board and the wallpaper picker (Hull is pale, Rock is orange). Settings has no checkmark on the selected accent and no card behind the swatches; the Materials previews are flat blue blocks; there's a visible seam in the Dark/Light segmented control. | `shell/triton/settings/AppearancePanel.qml:26` |
| 12 | Medium | Launcher: an empty query still shows a "Top hit" that duplicates the first row. The top-hit icon is a generic grid instead of the app's icon. Entry names show up as "(3.28 Flatpak) Files". Search is substring-only, with no fuzzy matching and no ranking by use. There's no search placeholder text. | `shell/triton/launcher/`, `services/LauncherService.qml` |
| 13 | Low | The window title is a separate center island (the board puts it in the left island) and is cut off by character count instead of fading at the edge. | `shell/triton/bar/Bar.qml:156` |
| 14 | Low | The lock-screen wallpaper is dimmed, not blurred. The comment says blur needs compositor cooperation; Qt's `MultiEffect` can blur it inside the shell. | `shell/triton/lock/LockWindow.qml:23` |
| 15 | Low | The wallpaper picker's thumbnails have square corners (the board has 16 px rounded corners with a primary-colored selected border). The Nebula scene is flat shapes, not the board's gradients. The "Live preview" chip is the wrong color. | `shell/triton/wallpaper/` |
| 16 | Low | Settings runs in the shell process, so a crash in Settings takes down the bar, lock screen and everything else. | `shell/triton/shell.qml` |
| 17 | Low | The brightness OSD finds the backlight with `sh -c ls`; the auto light/dark switch polls with a 60 s timer; there's no `sourceSize` on the wallpaper image (full-resolution decode, and `cache: false` re-decodes on every preview). | `shell/triton/shell.qml`, `Desktop.qml` |
| 18 | Hygiene | About 120 `.ppm`/`.png` screenshots are committed (`.git` is 124 MB). `.gitignore` has been line-sorted so its comments no longer sit next to their entries. `live-build/.lock` is tracked. `.github/workflows/` is empty. `README.md` still describes the old fuzzel + `triton-bar` layout. | repo root |

## Platform defects found by the stack research

From `docs/research/platform-stack.md`. Confirmed here: `bluez` is missing from
the built image, the Nautilus Flatpak is in the app list, and the engine sends
`pkill -HUP` to hypridle. The rest rests on the research, not on a booted ISO.

| # | Severity | Problem |
|---|---|---|
| 19 | Critical | hypridle has no SIGHUP handler, so `pkill -HUP` makes it exit, and systemd does not restart it. After the first setting change, idle timeouts and lock-before-suspend stop working. |
| 20 | High | `bluez` is not installed, so the Bluetooth panel and tile cannot work. |
| 21 | High | No portal backend provides the Secret interface, so sandboxed apps get no password store. |
| 22 | Medium | The lock screen's `login` PAM stack adds a 3 s delay on a wrong password and refuses unlock while `/etc/nologin` exists. |
| 23 | Medium | The preinstalled Nautilus Flatpak is a 2018 build on an end-of-life runtime (808 MB). |
| 24 | Medium | Flatpak language packs take about 1.2 GB because `languages` was not set at build time. |
| 25 | Low | Unneeded services are enabled (ifupdown, seatd, wait-online, apt timers); the `WLR_RENDERER` lines in `start-callisto` do nothing on Hyprland. |

## Visual comparison against the boards

| Surface | Matches the board | Doesn't match |
|---|---|---|
| Bar (revealed) | Island shapes, wave, workspace pills, clock and date, status pill | Pinned and window-title states are wrong (#1, #13); unreadable in light mode; nothing animates |
| Launcher | Overall structure, chips, sections, keycap hint bar | Top hit overflows and duplicates (#12); top hit stretches to full height instead of fitting its content; hint labels sit off the keycap baseline |
| Settings | Sidebar groups, panel header, segmented control | Not a floating window (#2); preview card has no wallpaper; swatches, contrast stops slider and materials previews are wrong (#11) |
| Lock | Date, clock, avatar, field, notification count | Card overlaps the clock; no blur; no notification list or media card; fingerprint text and battery always shown (#8) |
| Wallpaper picker | Preview banner, colors card, chips, Applying-to | Hint row overlaps labels; thumbnail corners and selection border; last thumbnail clipped (#15) |
| QS, notifications, OSD, power, overview, clipboard | Not checked against screenshots: no shipped screenshot of these exists | |

## Recommended order

**Phase 0: build a way to check against the boards (about 1 day).** Extend
`scripts/test-shell.sh` so it renders each surface at the board's size next to
the `render-board.sh` output, as a side-by-side or diff. Every later phase is
checked this way. Without it, "looks done" happens again.

**Phase 1: fix what's broken in daily use (1–2 days).** Defects 1–7: pinned
bar mode, Settings floating, the store and apply races, a per-domain engine
that only touches what changed, the scale bug, and keybinds that don't spawn a
systemd unit. Add defects 19–21. Follow the migration list in
`docs/research/platform-stack.md`.

**Phase 2: build the design-system layer (2–3 days).** Extend
`generate-theme.py` to produce a type scale, state layers, and veils and
materials that follow light/dark mode. Add centralized spring motion roles and
shared primitives and patterns (panel shell with enter and exit transitions,
card, list row, keycap, and so on), then remove every literal from surface
code. Add a lint check that fails CI on raw `pixelSize`, `radius` and hex
values outside `Theme`. Spec: `docs/design/component-system.md`.

**Phase 3: rebuild the surfaces from the component library, one at a time,
checked against the boards.** In order of how often people see them:
1. Bar (all four states)
2. Launcher
3. Quick Settings, notifications, OSD
4. Settings: a real resizable app window, possibly its own process
5. Lock screen
6. Wallpaper picker
7. Overview and power menu

Each surface gets its motion pass at the same time it's rebuilt.

**Phase 4: light mode and contrast (1 day).** Design light mode properly,
then run the contrast check across the board backgrounds, as the boards
themselves call for.

**Phase 5: finish or remove the half-built parts.** Wire in or delete the
screenshot tool, window switcher and greeter. Fix clipboard handling of
sensitive copies. Make the fingerprint hint conditional. Use a dedicated PAM
config.

**Phase 6: repo and release.** Stop tracking `.isotest/`, fix `.gitignore`,
add CI (lint, `qmllint`, ISO build, QEMU smoke test), and update `README.md`
and the architecture docs.

## Decisions taken

- The platform goes all in on Hyprland, systemd and Flatpak, with the modern
  Linux desktop stack (research and 20-step migration list:
  `docs/research/platform-stack.md`).
- The shell is rebuilt from semi-scratch on a component library, shadcn-style:
  every visual is a component, and tokens and motion are centralized. Services
  are kept where they're sound (spec:
  `docs/design/component-system.md`).
- `references/dux-shell` is a reference for patterns (popouts, animation) only.
  Triton keeps its own look.
