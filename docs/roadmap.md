# Callisto — Execution Roadmap

> **How to use this file:** Hand Phases 0–3 directly to a fast/cheap coding model to execute sequentially, one task at a time, with strict verification gates and clean git commits. Reserve Phase 4 for a frontier model (e.g., Opus) to polish visual fidelity, edge cases, and architecture docs. Add Phase 5 (CI/CD) once the ISO boots cleanly locally.

## 1. Project Target & Assignment Guardrails

- **Project Name:** **Callisto** — named for the oldest, most geologically unchanging surface in the Solar System, reflecting its rock-solid Debian Stable foundation.
- **Goal:** Build a reproducible, bootable **Debian 13 (`trixie`)** live ISO (**Callisto**) with a customized **Hyprland** Wayland desktop implementing the **Triton (Material 3 Futura)** visual identity, testable in QEMU.
- **Timeline:** 6 calendar days total.
- **Required Deliverables:**
  1. Bootable Debian ISO (`callisto-amd64.hybrid.iso`) testable in QEMU.
  2. GitHub repository (`callisto`) with source code, build scripts, and meaningful commit history.
  3. `README.md` with build and QEMU run instructions.
  4. `docs/ARCHITECTURE.md` covering architecture, implementation, design decisions, and **what was built from scratch vs. reused/customized**.
  5. 2-minute demo recording showing the running ISO and both desktop components.

### Hard Constraints for the Coding Agent (DO NOT DEVIATE)

1. **Debian only (`trixie` + `trixie-backports`):** Use Debian's official [`live-build`](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html) inside a `debian:trixie` container. Do **not** use Arch/`archiso` or compile `hyprland`, `quickshell`, or `niri` from source.
2. **Use packaged binaries:** Install [`hyprland`](https://packages.debian.org/trixie-backports/i386/x11/hyprland) and [`quickshell`](https://packages.debian.org/trixie-backports/quickshell) directly from `trixie-backports` via APT pinning.
3. **Clear component boundary:**
   - **Built from scratch:** `shell/triton-bar/` — Triton status bar implemented from scratch in Qt6/QML on top of the [Quickshell](https://packages.debian.org/sid/x11/quickshell) layer-shell toolkit.
   - **Customized existing component:** `configs/fuzzel/fuzzel.ini` — [Fuzzel](https://packages.debian.org/trixie/fuzzel) Wayland application launcher customized to match Triton tokens and wired to Hyprland + the bar's wave button.
4. **Never invent design tokens:** Use only the exact values from `design/tokens.json` (summarized in Section 3 below).
5. **One task, one verification, one commit:** Run the verification check at the end of every task before committing (`feat(iso): ...`, `feat(shell): ...`, `feat(theme): ...`).

## 2. Target Repository Structure

Create and maintain this exact layout so `live-build` stays clean and reproducible:

```text
callisto/
├── Makefile
├── Dockerfile.builder               # debian:trixie + live-build container
├── design/
│   ├── tokens.json                  # copied from Triton Shell-project.zip/triton/tokens.json
│   └── wallpaper.jpg                # copied from Triton Shell-project.zip/assets/78c3677ed5868bc238f3c39df7b47bb6.jpg
├── scripts/
│   ├── build-iso.sh                 # invokes containerized live-build
│   ├── sync-configs.sh              # copies shell/ + configs/ into live-build includes.chroot
│   └── run-qemu.sh                  # boots output ISO in QEMU (virtio-vga-gl + --sw fallback)
├── shell/
│   └── triton-bar/                  # FROM-SCRATCH COMPONENT (Quickshell QML)
│       ├── shell.qml                # entry point (PanelWindow / layer-shell)
│       ├── Theme.qml                # singleton generated from design/tokens.json
│       ├── Bar.qml                  # main 56px top bar layout
│       ├── WaveButton.qml           # 9-lobe Triton wave launcher button
│       ├── Workspaces.qml           # Hyprland IPC workspace pills
│       ├── Clock.qml                # "HH:mm ddd dd MMM" clock
│       └── StatusPill.qml           # PipeWire volume + network/battery status
├── configs/
│   ├── hypr/hyprland.conf           # Hyprland layout, keybinds, blur layer rules
│   ├── fuzzel/fuzzel.ini            # CUSTOMIZED EXISTING COMPONENT (launcher)
│   ├── greetd/config.toml           # default graphical session startup
│   └── gtk/gtk.css                  # Triton dark palette for GTK3/GTK4/libadwaita
├── live-build/
│   ├── auto/config                  # reproducible lb config flags
│   └── config/
│       ├── archives/
│       │   ├── backports.list.chroot
│       │   └── backports.pref.chroot
│       ├── package-lists/
│       │   └── callisto.list.chroot
│       ├── hooks/live/
│       │   └── 010-callisto-setup.hook.chroot
│       └── includes.chroot/         # populated by scripts/sync-configs.sh
├── docs/
│   └── ARCHITECTURE.md
├── .github/workflows/               # Phase 5 (CI)
└── README.md
```

## 3. Triton Design Token Quick Reference (Dark Scheme)

All colors, sizes, and shapes come verbatim from `design/tokens.json` (`Triton / Material 3 Futura v0.1.0`):

| Token | Value | Usage |
| --- | --- | --- |
| `surface` | `#111318` | Base dark background |
| `surface_container_lowest` | `#0C0E13` | Deepest inset container |
| `surface_container_low` | `#191C20` | Mica base fill (alpha `0.72`) |
| `surface_container` | `#1D2024` | Standard solid container |
| `surface_container_high` | `#282A2F` | Glass (`0.70`) & Thick Glass (`0.88`) fill |
| `surface_container_highest` | `#33353A` | Elevated solid control |
| `primary` / `on_primary` | `#B0C6FF` / `#002D6E` | Active focus, primary action |
| `primary_container` / `on_primary_container` | `#00429B` / `#D9E2FF` | Active workspace / selected chip |
| `secondary_container` / `on_secondary_container` | `#3F4759` / `#DBE2F9` | Tonal pill / inactive highlight |
| `tertiary` | `#FFB59B` | Warm accent |
| `on_surface` / `on_surface_variant` | `#E2E2E9` / `#C4C6D0` | Primary & muted text |
| `outline` / `outline_variant` | `#8E9099` / `#44474F` | Borders & dividers |
| `signal_warn` / `signal_info` | `#FFC857` / `#6FE0F5` | Warning & info indicators |
| `bar_height` | `56` px | Top bar height |
| `radius`: `tiled` / `sm` / `md` / `lg` / `xl` | `0` / `12` / `16` / `20` / `28` px | Tiled windows = `0`; floating/launcher = `28` |
| Fonts | `Jost` (display), `Google Sans Flex` or `Inter` fallback (UI), `JetBrains Mono` (mono), `Material Symbols Rounded` (icons) | Typography |

**Triton Visual Rules:**
1. Tiled windows have **zero gaps and `0px` corner radius** (`gaps_in = 0`, `gaps_out = 0`, `rounding = 0`). Radius and blur belong only to floating surfaces and shell panels.
2. **Glass** (`#282A2F` @ 70% alpha + compositor blur) for the bar and floating controls; **Thick Glass** (`#282A2F` @ 88% alpha) for the launcher; **Solid** for content. Never stack glass on glass.
3. The **9-lobe wave** (`shape.wave.path` in `design/tokens.json`, `viewBox="0 0 100 100"`) is used **only** for identity elements (launcher button, avatars, album art), never generic icons.

## 4. Phase-by-Phase Execution Plan

### Phase 0 — Repo Bootstrap (Owner: Cheap Model | Est: 30 min)

- [ ] **0.1 Initialize Git & Directory Tree**
  - Create the `callisto/` directory structure from Section 2.
  - Copy `triton/tokens.json` -> `design/tokens.json` and `assets/78c3677ed5868bc238f3c39df7b47bb6.jpg` -> `design/wallpaper.jpg`.
  - Add `.gitignore` excluding `live-build/.build/`, `live-build/cache/`, `live-build/chroot/`, `live-build/binary/`, `*.iso`, and `*.log`.
  - **Verify:** `git status` is clean after initial commit `chore: initialize callisto repository and import Triton design tokens`.

### Phase 1 — Bootable Debian ISO Skeleton + QEMU Boot (Owner: Cheap Model | Est: Day 1)

> **Priority #1:** Get a minimal Callisto ISO booting Hyprland in QEMU before writing a single line of QML. Follow the Debian 13 (`trixie`) [`live-build` workflow](https://rajib.uk/blog/build-custom-debian-iso/).

- [ ] **1.1 Create Builder Container (`Dockerfile.builder`)**
  - Base image: `debian:trixie`.
  - Install: `live-build`, `debootstrap`, `squashfs-tools`, `xorriso`, `isolinux`, `syslinux-common`, `grub-efi-amd64-bin`, `grub-pc-bin`, `mtools`, `dosfstools`, `ca-certificates`, `curl`.
  - **Verify:** `docker build -f Dockerfile.builder -t callisto-iso-builder .` succeeds.

- [ ] **1.2 Configure `live-build/auto/config`**
  - Set `lb config noauto` with:
    - `--distribution trixie`
    - `--architectures amd64`
    - `--binary-images iso-hybrid`
    - `--archive-areas "main contrib non-free-firmware"`
    - `--debian-installer none` (live-only ISO for fast QEMU boot; no slow disk installer needed)
    - `--bootappend-live "boot=live components quiet splash"`
    - `--image-name callisto`
    - `--iso-volume "CALLISTO_OS"`
    - `--backports true`
  - **Verify:** `bash -n live-build/auto/config` passes and script is executable (`chmod +x`).

- [ ] **1.3 Configure `trixie-backports` Repo & APT Pinning**
  - `live-build/config/archives/backports.list.chroot`:
    ```text
    deb http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
    ```
  - `live-build/config/archives/backports.pref.chroot`: pin `hyprland`, `hyprland-*`, `libaquamarine*`, `libhypr*`, and `quickshell` to `release a=trixie-backports` with `Pin-Priority: 600`.
  - **Verify:** Pinning syntax has valid `Package:`, `Pin:`, `Pin-Priority:` stanzas.

- [ ] **1.4 Create Package List (`live-build/config/package-lists/callisto.list.chroot`)**
  - Base live & graphics: `linux-image-amd64`, `live-boot`, `systemd-sysv`, `network-manager`, `dbus-user-session`, `polkitd`, `seatd`, `mesa-vulkan-drivers`, `libgl1-mesa-dri`, `libegl-mesa0`, `xwayland`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`.
  - Compositor & shell: `hyprland`, `quickshell`, `fuzzel`, `greetd`, `swaybg`, `mako-notifier`, `wl-clipboard`, `grim`, `slurp`.
  - Audio & utilities: `pipewire`, `pipewire-pulse`, `wireplumber`, `foot` (lightweight Wayland terminal), `thunar` or `nautilus`, `curl`, `jq`, `brightnessctl`.
  - Fonts: `fonts-jetbrains-mono`, `fonts-inter`, `fonts-noto-color-emoji`, `fonts-font-awesome` (plus fetch `Jost` and `Material Symbols Rounded` TTFs in `010-callisto-setup.hook.chroot` or bundle locally in `includes.chroot/usr/share/fonts/`).
  - **Verify:** No duplicate or non-Debian package names.

- [ ] **1.5 Configure Default Graphical Session (`configs/greetd/config.toml`)**
  - Configure `greetd` with `[initial_session]` autologin for the live user (`user`) running `/usr/local/bin/start-callisto`, which exports `XDG_SESSION_TYPE=wayland`, `XDG_CURRENT_DESKTOP=Hyprland`, handles software rendering fallback in QEMU if `/dev/dri/renderD128` lacks virgl acceleration, and execs `Hyprland`.
  - Set `/etc/os-release` / `/etc/hostname` (`callisto`) in `live-build/config/hooks/live/010-callisto-setup.hook.chroot`.
  - **Verify:** `configs/greetd/config.toml` is valid TOML.

- [ ] **1.6 Create Build & QEMU Scripts (`scripts/build-iso.sh`, `scripts/sync-configs.sh`, `scripts/run-qemu.sh`, `Makefile`)**
  - `scripts/sync-configs.sh`: copies `configs/*`, `shell/triton-bar/*`, and `design/wallpaper.jpg` into `live-build/config/includes.chroot/etc/skel/.config/...` and `/usr/share/backgrounds/callisto/`.
  - `scripts/build-iso.sh`: runs `sync-configs.sh`, then runs `lb clean && lb config && lb build` inside `callisto-iso-builder` (`--privileged`), outputting `callisto-amd64.hybrid.iso`.
  - `scripts/run-qemu.sh`: launches `qemu-system-x86_64` with `-enable-kvm -m 4096 -smp 4 -cpu host -device virtio-vga-gl -display gtk,gl=on -cdrom callisto-amd64.hybrid.iso`, plus a `--sw` flag falling back to `-device virtio-vga -display gtk` for hosts without OpenGL acceleration.
  - **Verify (Phase 1 Gate):** Run `make iso && make run`. Confirm Callisto boots to a working Hyprland session and `Super + Return` opens `foot`. Commit `feat(iso): add reproducible Debian trixie live-build pipeline and QEMU runner`.

### Phase 2 — From-Scratch Component: Triton Status Bar in Quickshell (Owner: Cheap Model | Est: Day 2–3)

> **Rule:** Keep QML clean, modular, and dependency-light. Test locally inside a running Hyprland session (or QEMU) using `quickshell -p shell/triton-bar` for instant hot-reload.

- [ ] **2.1 Generate `shell/triton-bar/Theme.qml` from `design/tokens.json`**
  - Create a `pragma Singleton` QML object exposing all Dark scheme colors, material RGBA helpers (`glassBg`, `thickGlassBg`, `micaBg`, `veil`, `veilHi`), radii (`rSm`, `rMd`, `rLg`, `rXl`), spacing scale, typography families, `barHeight: 56`, and the exact `wavePath` string from `design/tokens.json`.
  - **Verify:** `qmllint shell/triton-bar/Theme.qml` (if available) or `quickshell` loads it with zero warnings.

- [ ] **2.2 Build `WaveButton.qml` (Launcher Trigger)**
  - Render the 9-lobe Triton wave (`Shape` + `ShapePath` or `Canvas` using `Theme.wavePath` scaled to `36x36` inside a `44x44` hit target).
  - Hover state applies `Theme.veil`; click executes `fuzzel` via Quickshell `Process` (`pkill fuzzel || fuzzel`).
  - **Verify:** Clicking the wave icon toggles `fuzzel`.

- [ ] **2.3 Build `Workspaces.qml` (Hyprland IPC)**
  - Import `Quickshell.Hyprland`.
  - Render workspaces `1..5` (plus any occupied higher workspace) as pill indicators inside a subtle capsule.
  - Active workspace: `Theme.primary_container` (`#00429B`) fill with `Theme.on_primary_container` (`#D9E2FF`) text, wider pill (`width: 36`, `radius: 12`).
  - Occupied inactive workspace: `Theme.veil` fill with `Theme.on_surface`.
  - Empty workspace: subtle dot or muted number (`Theme.on_surface_variant` @ 50%).
  - Clicking any pill runs `Hyprland.dispatch("workspace " + wsId)`.
  - **Verify:** Switching workspaces via `Super + 1..5` or clicking pills updates immediately.

- [ ] **2.4 Build `Clock.qml`**
  - Use Quickshell `SystemClock` (minute precision).
  - Format matches `BarStates.dc.html`: `HH:mm  ddd dd MMM` (e.g., `21:41  Sat 21 Nov`) centered in the bar using `Theme.on_surface` and medium/semibold weight.
  - **Verify:** Clock renders centered and updates on the minute.

- [ ] **2.5 Build `StatusPill.qml` (Audio, Network, Battery)**
  - Capsule pill on the right side of the bar (`Theme.veil` background, `radius: 9999`, `height: 36`).
  - **Audio:** Read volume + mute state via `Quickshell.Services.Pipewire` (or lightweight `wpctl get-volume @DEFAULT_AUDIO_SINK@` poll fallback); scroll wheel adjusts volume, click toggles mute.
  - **Network:** Show connected/disconnected icon via `nmcli` or `/sys/class/net` check.
  - **Battery:** Read `/sys/class/power_supply/BAT*` if present; cleanly hide battery readout in QEMU/desktop VMs where no battery exists.
  - **Verify:** Volume mute/scroll works and QEMU VM shows no broken "0% battery" artifact.

- [ ] **2.6 Assemble `Bar.qml` & `shell.qml`**
  - `PanelWindow` anchored `top`, `left`, `right`, `implicitHeight: 56`, `exclusiveZone: 56`, transparent window background (`color: "transparent"`), inner glass bar fill `Theme.glassBg` (`#B3282A2F`) with `1px` top/bottom subtle highlight (`rgba(255,255,255,0.14)`).
  - Three-column layout: Left (`WaveButton` + `Workspaces`), Center (`Clock`), Right (`StatusPill`).
  - **Verify (Phase 2 Gate):** Run `quickshell -p shell/triton-bar` inside Hyprland; zero console errors, bar reserves `56px` exclusive zone so tiled windows never overlap it. Commit `feat(shell): implement Triton status bar from scratch in Quickshell`.

### Phase 3 — Customized Existing Component + System Theming (Owner: Cheap Model | Est: Day 4)

- [ ] **3.1 Customize Fuzzel (`configs/fuzzel/fuzzel.ini`)**
  - Style strictly from `design/tokens.json` Thick Glass spec:
    - `background=282a2fe0` (`surface_container_high` @ 88% alpha)
    - `text=e2e2e9ff` (`on_surface`)
    - `match=b0c6ffff` (`primary`)
    - `selection=00429bff` (`primary_container`)
    - `selection-text=d9e2ffff` (`on_primary_container`)
    - `selection-match=ffb59bff` (`tertiary`)
    - `border=8e909940`, `border-width=1`, `border-radius=28`
    - `font=Jost:size=13`, `prompt="Search apps  "`, `lines=8`, `width=42`, `horizontal-pad=24`, `vertical-pad=16`, `inner-pad=10`
  - **Verify:** Launch `fuzzel`, search for `foot`, press Enter to launch.

- [ ] **3.2 Write Hyprland Config (`configs/hypr/hyprland.conf`)**
  - **Layout (Triton Principle 1):** `gaps_in = 0`, `gaps_out = 0`, `border_size = 1`, `col.active_border = rgba(b0c6ff66)`, `col.inactive_border = rgba(44474f44)`, `rounding = 0` on tiled windows.
  - **Floating windows:** `windowrulev2 = rounding 28, floating:1`.
  - **Blur & layer rules:** enable `decoration:blur` (`size = 8`, `passes = 3`, `xray = false`) and add `layerrule = blur, quickshell` + `layerrule = ignorezero, quickshell` + `layerrule = blur, launcher` (for Fuzzel).
  - **Autostart (`exec-once`):** `swaybg -i /usr/share/backgrounds/callisto/wallpaper.jpg -m fill`, `quickshell -p ~/.config/quickshell/triton`, `mako`.
  - **Keybinds:**
    - `SUPER, Space` -> `pkill fuzzel || fuzzel`
    - `SUPER, Return` -> `foot`
    - `SUPER, Q` -> `killactive`
    - `SUPER, F` -> `togglefloating`
    - `SUPER, 1..5` -> `workspace 1..5`
    - `SUPER SHIFT, 1..5` -> `movetoworkspace 1..5`
  - **Verify:** `hyprctl reload` reports zero config errors.

- [ ] **3.3 Apply GTK3/GTK4 + Terminal + Notification Theming**
  - `configs/gtk/gtk.css`: define `@define-color window_bg_color #111318;`, `@define-color view_bg_color #191C20;`, `@define-color accent_bg_color #00429B;`, `@define-color accent_fg_color #D9E2FF;`, `@define-color window_fg_color #E2E2E9;` and install to both `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` + `settings.ini` (`gtk-application-prefer-dark-theme=1`).
  - Configure `foot.ini` (`background=191c20`, `alpha=0.85`, `foreground=e2e2e9`, `font=JetBrains Mono:size=11`) and `mako` config using Triton Glass hexes.
  - **Verify (Phase 3 Gate):** Run `make iso && make run`. Confirm live boot shows Callisto wallpaper, Triton bar, themed Fuzzel launcher, themed `foot`, and zero gaps on tiled windows. Commit `feat(theme): add Callisto Hyprland, Fuzzel, GTK, and terminal theming`.

### Phase 4 — Frontier Model Cleanup & Polish Pass (Owner: Opus / Frontier Model | Est: Day 5)

> **Hand off the working repo from Phases 0–3 to Opus with this checklist:**

- [ ] **4.1 Visual Fidelity Audit against Triton Boards**
  - Compare running bar & launcher against `BarStates.dc.html`, `Launcher.dc.html`, and `Main.dc.html`.
  - Refine QML spring animations (`Behavior on implicitWidth` / `NumberAnimation` or spring approximations matching `tokens.json` motion tokens) and shape morphing on active states (circle -> rounded square).
  - Verify contrast ratios on the real wallpaper (Dark Glass `0.70`, Thick Glass `0.88`).
  - *(Optional if time permits)* Add a compact QuickSettings or Power popover anchored to `StatusPill.qml`.

- [ ] **4.2 Edge-Case & QEMU Hardening**
  - Audit `start-callisto` wrapper for both KVM + `virtio-vga-gl` and software-rendered QEMU environments.
  - Ensure clean `quickshell` error handling when PipeWire or battery sysfs nodes are absent.
  - Clean up any temporary hacks, dead files, or hardcoded paths left by the cheap model.

- [ ] **4.3 Author High-Signal Documentation**
  - `README.md`: one-command build (`make iso`), one-command QEMU launch (`make run` / `make run-sw`), keybind cheatsheet, and hardware/VM requirements.
  - `docs/ARCHITECTURE.md`:
    - Wayland architecture explanation (DRM/KMS -> Hyprland/Aquamarine -> `wlr-layer-shell-unstable-v1` -> Quickshell surfaces -> Hyprland UNIX socket IPC).
    - Debian distribution engineering decisions (`live-build` stages, `trixie-backports` pinning, `includes.chroot` vs. live hooks, reproducibility).
    - Explicit attribution table: **Built from Scratch** vs. **Customized Existing** vs. **Reused Upstream**.

### Phase 5 — CI & Reliability Pipeline (Owner: You + AI | Bonus Engineering Signal)

> Add after Phase 3/4 works locally. Demonstrates real Linux platform engineering discipline.

- [ ] **5.1 Static Validation Workflow (`.github/workflows/lint.yml`)** — runs on every push/PR:
  - `shellcheck` on `scripts/*.sh`, `live-build/auto/config`, and `live-build/config/hooks/live/*`.
  - Validate `design/tokens.json` with `jq empty`.
  - Validate `configs/greetd/config.toml` with Python `tomllib`.
  - Run `qmllint` (in a `debian:trixie` container with `qt6-declarative-dev-tools`) on `shell/triton-bar/*.qml`.

- [ ] **5.2 Reproducible ISO Build Workflow (`.github/workflows/build-iso.yml`)** — runs on `workflow_dispatch` and release tags:
  - Builds `Dockerfile.builder`, sets `SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)` for reproducible timestamps, runs `scripts/build-iso.sh`.
  - Computes `SHA256SUMS` and uploads `callisto-amd64.hybrid.iso` + checksum as a GitHub Release / workflow artifact.

- [ ] **5.3 Headless QEMU Boot Smoke Test (`.github/workflows/qemu-smoke.yml`)**:
  - Boots `callisto-amd64.hybrid.iso` in QEMU (`-display none -serial stdio` or `-vnc :1`) with a timeout.
  - Verifies via serial log / guest check that systemd reaches multi-user/graphical target, `greetd` starts, and `Hyprland` + `quickshell` stay alive without crashing.

## 5. Final Submission Checklist (Day 6)

- [ ] Clean rebuild from scratch (`make clean && make iso`) succeeds without manual intervention.
- [ ] `callisto-amd64.hybrid.iso` boots cleanly in QEMU using the exact command in `README.md`.
- [ ] Both components are functional on boot: **Triton Status Bar** (from scratch) + **Themed Fuzzel Launcher** (customized).
- [ ] `git log --oneline` shows a clear, incremental commit history.
- [ ] `README.md` and `docs/ARCHITECTURE.md` clearly document from-scratch vs. customized components and Wayland/Debian architecture.
- [ ] 2-minute demo video recorded showing: QEMU boot -> Callisto desktop & theming -> Triton Bar (workspaces, wave button, clock, status pill) -> customized Fuzzel launcher -> opening & tiling/floating apps.