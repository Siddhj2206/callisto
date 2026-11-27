# Callisto platform stack — decisions for Hyprland + systemd + Flatpak

**Date:** 2026-11-27 · **Scope:** session, keybinds, settings engine, Flatpak, base services, installer, performance.
**Builds on:** `docs/research/desktop-os-essentials.md`, `docs/research/distro-engineering.md`, `docs/research/live-build.md`, `docs/research/quickshell-optimization.md`, `docs/design/settings-architecture.md`. Those documents remain valid unless a section below corrects them.

## How this was verified

- **Real versions come from the last ISO build**, not from memory: `live-build/chroot.packages.install`, plus unit files, portal files, PAM stacks and Quickshell `.qmltypes` read from `live-build/chroot/`.
- **Archive availability** was checked against the Debian archive API (`api.ftp-master.debian.org/madison`, suites `trixie` and `trixie-backports`) on 2026-11-27.
- **Upstream behaviour** was checked in source at the tag that is actually shipped: hypridle v0.1.8, xdg-desktop-portal 1.20.3, Calamares v3.3.14 and uwsm v0.26.7 README. Docs used: Quickshell v0.3.0 and the Hyprland 0.55 wiki.
- **Timings** were measured on the dev host (Fedora, fast desktop). They give orders of magnitude only. A VM will be slower.
- Anything not verified this way is marked **(verify)**.

### New defects found while verifying (not in the original audit)

| # | Defect | Evidence |
|---|---|---|
| N1 | **`callisto-apply` kills hypridle.** The engine sends `pkill -HUP hypridle`, but hypridle 0.1.8 has no signal handler, so SIGHUP's default action terminates it. systemd counts death by SIGHUP as a *clean* exit, so the shipped unit's `Restart=on-failure` never restarts it. After the first idle-setting change the machine has no idle handling and no lock-before-sleep. | `src/core/Hypridle.cpp` at v0.1.8 has no `signal`/`sigaction`; `/usr/lib/systemd/user/hypridle.service` has `Restart=on-failure`; `systemd.service(5)` treats SIGHUP/SIGINT/SIGTERM/SIGPIPE as clean. |
| N2 | **The Secret portal resolves to nothing.** `hyprland-portals.conf` is `default=hyprland;gtk`. Neither backend implements `org.freedesktop.impl.portal.Secret`, and `gnome-keyring.portal` says `UseIn=gnome`. Sandboxed apps that use libsecret's portal path get no secret store. | `/usr/share/xdg-desktop-portal/hyprland-portals.conf` and the `portals/*.portal` files in the chroot |
| N3 | **BlueZ is not installed.** Only `libspa-0.2-bluetooth` is, so Bluetooth cannot work on the ISO even though the Settings app has a Bluetooth panel. | no `bluez` in `chroot.packages.install`; no `bluetoothctl` |
| N4 | **The preinstalled Flathub `org.gnome.Nautilus` is a 2018 build** on the EOL `org.gnome.Platform//3.28` runtime. That runtime adds 808 MB for one app, and the app is delisted (Flathub appstream API: "App not found"; summary timestamp 1525339910 = May 2018). | `var/lib/flatpak/app/org.gnome.Nautilus/.../metadata`; flathub.org API |
| N5 | **Flatpak locale extensions take 1.2 GB** (`org.freedesktop.Platform.Locale` 885 MB, `org.gnome.Platform.Locale` 328 MB). Flatpak's `languages` config was not set at build time. In total `/var/lib/flatpak` is 5.5 GB uncompressed. | `du` in the chroot |
| N6 | **The lock screen authenticates against `login`.** That stack pulls in `pam_nologin`, which refuses unlock whenever `/etc/nologin` exists (e.g. during shutdown), `pam_faildelay delay=3000000` (a 3 s penalty per typo) and login session modules. hyprlock ships its own `/etc/pam.d/hyprlock` for exactly this reason. | `/etc/pam.d/login` and `/etc/pam.d/hyprlock` in the chroot |
| N7 | **Redundant boot services are enabled:** `networking.service` (ifupdown) alongside NetworkManager, `NetworkManager-wait-online`, `seatd.service` alongside logind, `ModemManager`, and the `apt-daily*` timers on a live ISO. | `etc/systemd/system/*.wants` |
| N8 | **`WLR_RENDERER=pixman` / `WLR_RENDERER_ALLOW_SOFTWARE` in `start-callisto` do nothing.** Those are wlroots variables. Hyprland uses aquamarine and has no pixman renderer. | `scripts/start-callisto` |
| N9 | **foot 1.21 (trixie) cannot switch theme at runtime**, and `foot-server.service`/`.socket` are globally enabled by the package. A footclient window would show the server's stale theme until the server restarts. | `/etc/systemd/user/graphical-session.target.wants/foot-server.*`; foot 1.21 changelog |

---

## (a) Decision summary

| Area | Decision | Why | Package / unit |
|---|---|---|---|
| Session manager | **Keep uwsm.** Use it to start the session and to launch real apps. Never put it on a keypress path. | uwsm gives correct env propagation, `graphical-session.target`, ordered teardown and slices. Its cost is a Python start, which only matters per keypress. | `uwsm 0.26.7` (bpo), `wayland-wm@hyprland.service` |
| Session services | Every long-lived session process is a **systemd user unit** with `PartOf=`/`After=graphical-session.target` and `Restart=on-failure`. Nothing is started from `hl.on("hyprland.start")`. | Crash recovery, journald logs, ordering, and no processes inside the compositor's unit | `callisto-shell.service`, `callisto-settingsd.{socket,service}`, `callisto-clipboard.service`; packaged `hypridle`, `hyprsunset`, `hyprpolkitagent`, portals |
| App launching | `uwsm-app -- <id>.desktop`, served by the packaged `wayland-wm-app-daemon.service`. Not `uwsm app`. | Same slices and scopes, without a Python start on every launch | `uwsm-app` (ships in the uwsm package) |
| Shell keybinds | **Quickshell `GlobalShortcut`** (`hyprland_global_shortcuts_v1`) bound with `hl.dsp.global("callisto:<name>")`. `qs ipc` stays for scripts, hypridle and debugging. | No process per keypress at all. Today each press costs a Python start, a transient scope and a ~41 ms `qs` client. | `Quickshell.Hyprland` (qs 0.3.0) |
| Media keys | `wpctl`, `brightnessctl` and `playerctl` **exec'd directly, without uwsm**. The shell observes PipeWire and the backlight to show the OSD. | C binaries take a few ms. The keys keep working if the shell is dead. uwsm's README itself says one-off commands like volume changes are fine in the compositor unit. | — |
| Settings engine | Make it a **long-lived Python daemon** (`callisto-settingsd`), socket-activated. It is the only writer of the store (atomic with fsync), debounces changes, diffs them by domain and runs only the affected appliers in-process (Gio for gsettings and D-Bus). | Removes one process per change and the non-atomic `sh -c cat >`. Python startup is paid once. | `python3`, `python3-gi` (already installed); `%t/callisto/settingsd.sock` |
| Accent colour for apps | The settingsd daemon also serves an **`org.freedesktop.impl.portal.Settings` backend** ("callisto"), placed before gtk in `hyprland-portals.conf`. It publishes `accent-color`, `color-scheme` and `contrast`. | xdp-gtk 1.15.3 publishes only `color-scheme` and `contrast` (checked in the binary). xdp 1.20.3 queries every configured Settings backend in order and takes the first answer (checked in source). | `/usr/share/xdg-desktop-portal/portals/callisto.portal` |
| Portals | `default=hyprland;gtk`, plus `Settings=callisto;gtk`, plus **`Secret=gnome-keyring`** (fixes N2) | XDPH: Screenshot, ScreenCast, GlobalShortcuts, InputCapture. gtk: FileChooser, AppChooser, Print, Notification, Inhibit, Access, Account, Email, DynamicLauncher, Lockdown, Settings. | `/etc/xdg/xdg-desktop-portal/hyprland-portals.conf` |
| Secrets | **gnome-keyring 48**, unlocked by PAM at greeter login, plus `gcr-ssh-agent` | oo7 is not packaged in Debian. KWallet is heavier and Qt-centric. gnome-keyring is already installed and socket-activated. | `gnome-keyring`, `libpam-gnome-keyring` |
| Lock screen | Triton lock with a **dedicated `/etc/pam.d/callisto-lock`**, plus an optional parallel fingerprint context. Set Hyprland `misc.allow_session_lock_restore = true`. | Fixes N6. Lets a crashed or restarted shell re-lock. | `libpam-fprintd` (optional) |
| Clipboard | **`wl-paste --watch` → tiny `sh` filter → `cliphist store`**, run as a user service. Skip `x-kde-passwordManagerHint`. | One compiled tool per event instead of Python. Handles images. wl-clipboard never sets `CLIPBOARD_STATE=sensitive` (its own man page says so), so the MIME hint must be checked explicitly. | `cliphist 0.5.0`, `wl-clipboard 2.2.1` |
| Shell vs Settings process | Settings runs as a **separate Quickshell instance from the same config tree** (`qs -n -p …/settings-app.qml`), launched as an app | A crash or reload of Settings can't take down the bar or the lock. It costs no RAM until opened. | `org.callisto.Settings.desktop` |
| Polkit agent | Keep **hyprpolkitagent** for 0.1. Move to the in-shell `Quickshell.Services.Polkit` agent once the shell is a supervised service. | Visual consistency later; reliability now | `hyprpolkitagent 0.1.3` (bpo) |
| Greeter | **greetd + Quickshell greeter** (`Quickshell.Services.Greetd`) running in a minimal Hyprland, with tuigreet as fallback. Autologin `initial_session` on the live ISO only. | Same renderer and look as the session. `Greetd` is in qs 0.3.0. | `greetd 0.10.3`, `/usr/share/callisto/greeter/` |
| Audio | PipeWire + WirePlumber. **Stay on trixie 1.4.2/0.5.8 for 0.1.** Consider backports 1.6.9/0.5.12 later. | Already working. Bluetooth codecs present: SBC, aptX, LDAC, LC3, Opus (AAC absent). | `pipewire-audio`, `libspa-0.2-bluetooth` |
| Network | **NetworkManager + wpa_supplicant** (default backend). **Remove ifupdown**, disable `NetworkManager-wait-online`. | iwd 3.8 is available, but NM's iwd backend still has gaps (verify before switching). wpa_supplicant is the Debian and Fedora default. | `network-manager 1.52` |
| Bluetooth | **Add `bluez`** (fixes N3). The shell drives it through `Quickshell.Bluetooth`. | — | `bluez 5.82` |
| Power | power-profiles-daemon. **The shell sets the profile directly** with `Quickshell.Services.UPower` `PowerProfiles`, so it leaves the settings store. | ppd persists its own state, and `powerprofilesctl` is itself a Python script | `power-profiles-daemon 0.30` |
| Memory | **systemd-oomd + zram** (zstd) | No swap on a live ISO. Debian's oomd package already ships the Fedora-style defaults. | `systemd-oomd`, `systemd-zram-generator 1.2.1` |
| Homes | **No systemd-homed** | Little user benefit. It complicates Calamares, PAM and greetd, and nothing else in the stack needs it. | — |
| Bootloader | **GRUB through Debian's signed shim** on the live ISO and on installed systems. Revisit systemd-boot/UKI with an image-based design. | Secure Boot works out of the box only along Debian's signed chain. A UKI you build locally isn't Debian-signed. | `shim-signed`, `grub-efi-amd64-signed` |
| initramfs | **initramfs-tools** | `live-boot` is an initramfs-tools hook. Debian plans to switch to dracut during forky; trixie still defaults to initramfs-tools. | `initramfs-tools 0.148` |
| Boot splash | **Plymouth** with a Callisto theme and `plymouth quit --retain-splash` handed off to the greeter | `splash` is already on the cmdline but Plymouth isn't installed | `plymouth 24.004`, `plymouth-themes` |
| Firmware | fwupd with `fwupd-refresh.timer` and a Settings "Firmware" row | Standard. 2.0.20 in stable, 2.1.7 in backports. | `fwupd` |
| Location | Sunrise and sunset from the **timezone's coordinates** (`zone1970.tab`) by default; GeoClue opt-in | Needs no network or privacy prompt and works offline | `python3-astral 3.2` (or ~30 lines of NOAA maths); `geoclue-2.0 2.7.2` optional |
| Flatpak | Flathub via `/etc/flatpak/remotes.d/`. Preinstall at build time with **`languages` pinned**. Drop the 2018 Nautilus. Shell, terminal, file manager, disks, installer and printing come from debs; user apps from Flathub. | Fixes N4 and N5. Flatpak 1.16 (trixie) has no `preinstall.d`; that arrived in 1.17. | `flatpak 1.16.6` |
| Installer | **Calamares 3.3.14** with a forked `calamares-settings-debian`, unpacking the live squashfs | It's what Debian's own live images use, and greetd support exists, with a caveat (§6) | `calamares`, `calamares-settings-debian` |
| Image-based | **Not now.** Track ostree (Endless OS is the Debian precedent) or mkosi + repart for a 1.x. | `systemd-sysupdate` isn't shipped by Debian, so A/B has no packaged updater | `ostree 2025.2`, `mkosi 25.3` exist |
| Compositor GPU | Default "glass" at **passes 2**, xray on for shell layers, **no shadows on tiled windows**, `vrr = 2`, `direct_scanout = 2` | Blur cost grows with passes. Shadows under zero-gap tiled windows are invisible but still drawn. | `hyprland.lua` |

---

## (b) Target session architecture

```
SYSTEM (PID 1)
  sysinit: systemd-zram-setup@zram0 (generator), systemd-oomd, timesyncd, apparmor
  multi-user: NetworkManager, bluetooth, power-profiles-daemon, upower, udisks2 (on demand), fwupd (on demand)
  graphical.target
   └─ display-manager.service = greetd.service      (After=plymouth-start; drop-in: quit --retain-splash)
        ├─ greeter (installed): Hyprland --config /usr/share/callisto/greeter/hyprland.lua
        │     └─ qs -p /usr/share/callisto/greeter/greeter.qml   → Greetd.launch(["/usr/bin/start-callisto"])
        └─ PAM "greetd" → pam_systemd → user@1000.service (systemd --user, dbus-broker)

USER MANAGER (user@1000)
  default.target / sockets.target   (independent of the compositor)
    pipewire.socket → pipewire.service → wireplumber.service
    pipewire-pulse.socket, gnome-keyring-daemon.socket, gcr-ssh-agent.socket, dbus.socket (broker)

  start-callisto  ── exec uwsm start -- hyprland.desktop
    wayland-session-pre@hyprland.target
      graphical-session-pre.target   ← gnome-keyring-daemon.service, xdg-desktop-portal-rewrite-launchers
      wayland-wm-env@hyprland.service       (env preload: /etc/xdg/uwsm/env, env-hyprland)
    wayland-wm@hyprland.service             Type=notify, session.slice  — Hyprland 0.55
    wayland-session@hyprland.target
      graphical-session.target              (reached once Hyprland exports WAYLAND_DISPLAY)
        │  After=graphical-session.target, PartOf=graphical-session.target for all of:
        ├─ callisto-shell.service           session-graphical.slice  qs -n -c triton   Restart=on-failure
        ├─ callisto-settingsd.socket ──►    callisto-settingsd.service  background-graphical.slice  Type=notify
        │                                     also owns D-Bus name org.freedesktop.impl.portal.desktop.callisto
        ├─ hyprpolkitagent.service          session.slice
        ├─ hypridle.service                 (static logind/lock hooks + timeouts; restarted, never HUP'd)
        ├─ hyprsunset.service               session.slice (IPC: hyprctl hyprsunset …)
        ├─ callisto-clipboard.service       background-graphical.slice  wl-paste --watch …
        ├─ wayland-wm-app-daemon.service    on demand (first uwsm-app call)
        ├─ fumon.service                    notifies on failed user units (needs notify-send: present)
        ├─ [D-Bus activated] xdg-desktop-portal.service
        │       ├─ xdg-desktop-portal-hyprland  (Screenshot, ScreenCast, GlobalShortcuts, InputCapture)
        │       ├─ xdg-desktop-portal-gtk       (FileChooser, AppChooser, Print, Notification, Inhibit, Settings[fallback] …)
        │       ├─ gnome-keyring                (Secret)
        │       └─ callisto-settingsd           (Settings: accent-color, color-scheme, contrast)
        ├─ [D-Bus activated] flatpak-session-helper, flatpak-portal, xdg-document-portal
        └─ xdg-desktop-autostart.target  → app-*@autostart.service
    apps (all launches): app-graphical.slice/app-<desktop-id>-<rand>.scope   via uwsm-app
    on-demand app:       Settings = qs -n -p …/triton/settings-app.qml  (its own scope)

  Keypress paths (no process spawned unless stated)
    Super+Space ──Hyprland bind──► hl.dsp.global("callisto:launcher") ──wayland──► GlobalShortcut.onPressed
    Volume keys ──Hyprland bind──► exec wpctl (≈ms, inside compositor cgroup, fine) ──PipeWire──► shell OSD
    Super+Return ─Hyprland bind──► exec uwsm-app -- foot.desktop  (shell client → app-daemon → systemd scope)

  Teardown: Settings / shell / power menu → `uwsm stop` (never Hyprland's exit dispatcher)
```

**Ordering notes**

- **Nothing in the shell's path waits on settingsd.** Tokens and generated files are compiled once at build time into `/etc/skel`, and on every run afterwards are written atomically by settingsd, so `tokens.json` always exists when the shell starts. That removes the "theme seeding must precede the shell" step in `start-callisto` and lets the shell and settingsd start in parallel.
- **Portals are D-Bus activated.** They need `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` in the activation environment, which uwsm provides. Don't start them by hand.
- **`hl.on("hyprland.start")` becomes empty** (or only `uwsm finalize`, if ever needed).

---

## (c) Per-area detail

### 1. Session: uwsm vs plain systemd units

**Verdict: keep uwsm as the session envelope, and stop using `uwsm app` as a prefix for everything.**

Without uwsm, the same session would need:

- A hand-written `hyprland-session.target`.
- `dbus-update-activation-environment --systemd …` after start.
- A compositor unit with sd_notify readiness.
- A bindpid unit that ties the graphical session to the login session.
- Cleanup of the activation environment at logout.

That is exactly what `wayland-wm@.service`, `wayland-wm-env@.service` and `wayland-session-bindpid@.service` already do, and they ship tested in backports. The only real cost of uwsm is Python start-up in `uwsm app`. That cost lives on the app-launch path, which has a packaged fix (`uwsm-app` plus `wayland-wm-app-daemon.service`), and on the keypress path, where Callisto shouldn't spawn anything at all.

**What must *not* go through `uwsm app` / `uwsm-app`:**

| Command | Why not | Instead |
|---|---|---|
| `qs … ipc call …` | It's a client talking to an existing process, not an app. A scope for a 40 ms client is pure overhead. | `GlobalShortcut`. Plain `qs ipc call` (no prefix) from hypridle and scripts. |
| `wpctl`, `brightnessctl`, `playerctl` | Short-lived. uwsm's README: processes in the compositor unit are "mostly OK for short-lived one-off commands, i.e. volume adjustment" | Direct `hl.dsp.exec_cmd("wpctl …")` |
| `hyprctl …` | Same | Direct |
| The shell, clipboard watcher, polkit agent, idle daemon | They're session services: they need restart policy, logs and ordering, not a fire-and-forget scope | systemd user units |
| `uwsm stop` | It's the session controller | Direct |

**Measured cost components** (dev host, mean of 20 runs):

| Component | Time |
|---|---|
| `systemd-run --user --scope true` | 6 ms |
| `systemd-run --user --wait --collect true` | 19 ms |
| `python3 -I -c "import json,subprocess,argparse,shlex,os"` | 24 ms (uwsm imports far more, so expect several times this) |
| `qs ipc call` client | 41 ms |
| `sh -c` | 1 ms |

Today's keybind path is therefore one uwsm Python start, plus a transient unit, plus a Qt client start, plus IPC. That is easily 100 ms or more on real hardware, and worse in QEMU. The GlobalShortcut path spawns nothing.

**Units to ship** in `/usr/lib/systemd/user/`, enabled with `systemctl --global enable` in the hook:

```ini
# callisto-shell.service
[Unit]
Description=Callisto shell (Triton)
PartOf=graphical-session.target
After=graphical-session.target
Requisite=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY
StartLimitIntervalSec=30
StartLimitBurst=5

[Service]
Type=exec
# -n: refuse a duplicate instance (qs 0.3.0 flag)
ExecStart=/usr/bin/qs -n -c triton
Restart=on-failure
RestartSec=300ms
Slice=session-graphical.slice

[Install]
WantedBy=graphical-session.target
```

```ini
# callisto-clipboard.service
[Unit]
Description=Callisto clipboard history
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=exec
ExecStart=/usr/bin/wl-paste --watch /usr/libexec/callisto/clip-store
Restart=on-failure
Slice=background-graphical.slice

[Install]
WantedBy=graphical-session.target
```

The settingsd units are in §3.

The packaged units `hypridle.service`, `hyprsunset.service` and `hyprpolkitagent.service` already have `WantedBy=graphical-session.target` and are already enabled globally in the image. hypridle's unit has no `Slice=`, so it lands in `app.slice`. Optionally add a drop-in with `Slice=session.slice`.

**Restart-on-crash and the lock screen.** If the shell dies while locked, Hyprland's `ext-session-lock` shows the "lockdead" screen. Fix it in two parts:

1. In `hyprland.lua`: `misc = { allow_session_lock_restore = true }` (the option exists in the 0.55 variables page).
2. `LockState` writes `$XDG_RUNTIME_DIR/callisto/locked` when it locks and removes it when it unlocks. On startup the shell re-locks if the marker exists. This works because `XDG_RUNTIME_DIR` survives a shell restart but not a reboot.

**Logout.** Always `uwsm stop`. This was already stated in `modern-stack.md`; keep it.

**`start-callisto` becomes:**

```bash
#!/bin/sh
# Session entry from greetd. Environment lives in /etc/xdg/uwsm/env*, theming is precompiled.
if uwsm check may-start >/dev/null 2>&1; then
    exec uwsm start -- hyprland.desktop
fi
exec Hyprland   # last resort: never strand a live user on a TTY
```

Drop the `WLR_*` exports (N8). In VMs, the software path is Mesa llvmpipe through GBM, which needs no variable. Drop the pre-launch `callisto-apply`. Drop the log redirections: uwsm and Hyprland log to the journal (`journalctl --user -u wayland-wm@hyprland`).

### 2. Keybind → shell latency

**Use `GlobalShortcut`** (Quickshell docs v0.3.0). It implements `hyprland_global_shortcuts_v1` directly and bypasses the portal, so XDPH isn't involved.

- Hyprland triggers a shortcut through the `global` dispatcher. The 0.55 Lua form is `hl.dsp.global("<appid>:<name>")`, as written in the 0.55 Binds wiki.
- Registered shortcuts can be listed with `hyprctl globalshortcuts`.
- **Caveat:** if two clients register the same `appid:name`, the last one to register crashes. Use a distinct appid, `callisto`, not the default `quickshell`, so nothing collides with XDPH or other qs instances.

```qml
// shell.qml (or a Shortcuts.qml) — replaces the IpcHandler block for keybinds
import Quickshell.Hyprland

component Shortcut: GlobalShortcut { appid: "callisto" }

Shortcut { name: "launcher";      description: "Toggle launcher";       onPressed: LauncherState.toggle() }
Shortcut { name: "overview";      description: "Toggle overview";       onPressed: OverviewState.toggle() }
Shortcut { name: "clipboard";     description: "Clipboard history";     onPressed: ClipboardState.toggle() }
Shortcut { name: "notifications"; description: "Notification centre";   onPressed: NotificationState.toggle() }
Shortcut { name: "quicksettings"; description: "Quick settings";        onPressed: QuickSettingsState.toggle() }
Shortcut { name: "power";         description: "Power menu";            onPressed: PowerState.toggle() }
Shortcut { name: "wallpaper";     description: "Wallpaper picker";      onPressed: WallpaperState.open ? WallpaperState.close(true) : WallpaperState.show() }
Shortcut { name: "lock";          description: "Lock screen";           onPressed: LockState.lock() }
// keep IpcHandler targets too: hypridle lock_cmd, scripts, tests use `qs -c triton ipc call …`
```

```lua
-- hyprland.lua
local function shell(name) return hl.dsp.global("callisto:" .. name) end
hl.bind(mod .. " + Space",     shell("launcher"))
hl.bind(mod .. " + Tab",       shell("overview"))
hl.bind(mod .. " + V",         shell("clipboard"))
hl.bind(mod .. " + N",         shell("notifications"))
hl.bind(mod .. " + I",         shell("quicksettings"))
hl.bind(mod .. " + SHIFT + E", shell("power"))
hl.bind(mod .. " + SHIFT + W", shell("wallpaper"))
hl.bind(mod .. " + Escape",    shell("lock"))
hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("uwsm-app -- foot.desktop"))

-- Media keys: direct exec, no uwsm. The shell's PipeWire/backlight observers show the OSD.
local media = { repeating = true, locked = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), media)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), media)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q set 5%+"), media)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 5%-"), media)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
```

**Why the volume keys don't go through the shell.** The alternative is a shortcut whose handler writes `Pipewire.defaultAudioSink.audio.volume`, which `Quickshell.Services.Pipewire` supports. It would be equally fast, but a shell crash or restart would kill the volume keys. Direct `wpctl` costs a few ms and always works. The OSD comes from a PipeWire observer: bind to `Pipewire.defaultAudioSink.audio.volume`/`muted` changes. This closes audit item C14 with no IPC target needed.

**Launching from the shell.** Launcher activation, the power menu's terminal and similar must go through `Quickshell.execDetached(["uwsm-app", "--", entry.id + ".desktop"])`. Otherwise apps become children of `callisto-shell.service` and die when the shell restarts. This matters more once the shell is a restartable unit.

**(verify)** Whether `{ locked = true }` on an `hl.dsp.global` bind delivers to a client that currently holds the session lock. It should, since the lock surface is the same qs client. Test lock-screen shortcuts if any are planned.

**(verify)** How `repeating = true` combines with `global` (repeated `pressed` signals, or one). It's irrelevant for toggles.

### 3. Settings and config pipeline

**Current problems.**

- Every `set()` starts `sh -c 'cat > settings.json'`, which is non-atomic and can be read half-written by FileView watchers.
- It then runs `callisto-apply`, a cold Python start of 80 ms or more.
- `callisto-apply` re-emits every output and re-pushes every live value: `hyprctl eval` twice, `hyprctl hyprsunset`, a hypridle rewrite plus `pkill -HUP` (N1), `powerprofilesctl` (a Python script, so a second interpreter start), and four `gsettings` processes.
- The shell's one-minute auto-mode timer spawns the whole engine again on a day/night flip.

**Target design: `callisto-settingsd`**, a long-lived Python 3.13 user daemon.

```
Settings app / shell ──(unix socket, JSON lines)──► callisto-settingsd
   {"op":"set","key":"appearance.accent","value":"#E58A4B"}        │
   {"op":"get"} / {"op":"subscribe"}                               │ validate against schema (v1)
                                                                   │ merge into in-memory store
                                                                   │ write store: tmp + fsync + rename + fsync(dir)
                                                                   │ debounce 120 ms trailing (slider drags coalesce)
                                                                   │ diff(prev_applied, store) → dirty domains
                                                                   ▼
            appliers (only dirty domains, each idempotent, each writes outputs atomically)
            ├─ palette    accent/contrast/wallpaper/mode → matugen (cached) → tokens.json, gtk-3/4 css,
            │             foot-theme.ini, qt6ct colors; Gio.Settings color-scheme/gtk-theme;
            │             emit portal SettingChanged(accent-color/color-scheme/contrast); hyprctl eval borders
            ├─ material   → hyprctl eval decoration.blur/shadow
            ├─ input      → hyprctl eval input{…}
            ├─ display    → hyprctl eval monitor/vrr ; night light → hyprsunset IPC
            ├─ idle       → write hypridle.conf → systemctl --user try-restart hypridle.service (D-Bus, Gio)
            ├─ cursor/fonts → Gio.Settings + hyprctl setcursor
            └─ schedule   in-process timer: auto dark/light + night light at sunrise/sunset (no shell timer)
```

**Decisions.**

- **The transport is a unix socket, not D-Bus, for the shell.** Quickshell 0.3.0 has `Quickshell.Io.Socket` but no generic D-Bus client; there are only typed service modules. So the Settings app speaks JSON lines over `%t/callisto/settingsd.sock`.
  - The daemon still uses D-Bus outward: Gio for gsettings, systemd, ppd if ever needed, and to *serve* the portal Settings backend.
  - A small CLI, `callisto-settings get|set|watch`, uses the same socket for scripts and tests.
- **The daemon is the single writer of the store.** The shell and the Settings app read through `FileView { watchChanges: true }` and update their UI optimistically. This makes rule 2 in `settings-architecture.md` actually true. Atomic write:

  ```python
  def write_atomic(path: Path, data: bytes) -> None:
      path.parent.mkdir(parents=True, exist_ok=True)
      fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
      try:
          os.write(fd, data); os.fsync(fd)
      finally:
          os.close(fd)
      os.replace(tmp, path)
      dfd = os.open(path.parent, os.O_DIRECTORY); os.fsync(dfd); os.close(dfd)
  ```

  The existing `atomic_write` in `callisto-apply` is right apart from the missing fsyncs. Reuse it.
- **Debounce plus diff by domain** (domain = top-level store section, refined per key where cheaper):
  - A palette change runs matugen at most once per distinct input; the existing cache keyed on path, mtime and contrast stays.
  - An input change runs one `hyprctl eval`.
  - A keyboard-repeat change no longer touches gsettings, hypridle or ppd.
- **Remove machine state from the store.**
  - The power profile is set by the shell through `Quickshell.Services.UPower` `PowerProfiles`; ppd persists it.
  - Night-light on/off is user preference and stays. Volume is already out.
- **Keep shell-only keys out of settingsd.** `shell.*` (bar mode, clock format, reduceMotion) is read by the shell straight from the store, and settingsd has no applier for it.
- **hyprctl stays a subprocess.** It's a C++ binary of a few ms, called once per debounced batch. Writing Hyprland's socket protocol directly is an optional later optimisation (verify the `eval` wire format first).
- **systemd units:**

  ```ini
  # callisto-settingsd.socket
  [Unit]
  Description=Callisto settings daemon socket
  PartOf=graphical-session.target
  [Socket]
  ListenStream=%t/callisto/settingsd.sock
  SocketMode=0600
  DirectoryMode=0700
  [Install]
  WantedBy=graphical-session.target

  # callisto-settingsd.service
  [Unit]
  Description=Callisto settings daemon
  PartOf=graphical-session.target
  After=graphical-session.target
  Requires=callisto-settingsd.socket
  [Service]
  Type=notify
  NotifyAccess=main
  ExecStart=/usr/libexec/callisto/settingsd
  Restart=on-failure
  Slice=background-graphical.slice
  ```

  Implementing `READY=1` needs no dependency: send a datagram to `$NOTIFY_SOCKET` with the `socket` module.
  ```ini
  # /usr/share/dbus-1/services/org.freedesktop.impl.portal.desktop.callisto.service
  [D-BUS Service]
  Name=org.freedesktop.impl.portal.desktop.callisto
  Exec=/bin/false
  SystemdService=callisto-settingsd.service
  ```
- **A path unit is not enough on its own.** A `.path` watching `settings.json` plus a oneshot service still costs one Python start per batch and has no idea what changed. It's acceptable as a stopgap: `PathChanged=` coalesces while the service runs. But the daemon is not much more code and removes the cold start.

**Should it stay Python? Yes.**

- Python 3.13 and `python3-gi` are already in the image; uwsm pulls in Python anyway.
- The steady-state cost was always process creation, never Python itself.
- Gio gives gsettings, D-Bus client and D-Bus server (for the portal backend) in-process.
- Expect roughly 25–35 MB RSS. Rust or C++ would save RAM but cost iteration speed on the part of the system that changes most.
- The only hot computation is matugen, which is already an external binary, and its results are cached.

**The portal Settings backend** (settingsd exports it with Gio):

```ini
# /usr/share/xdg-desktop-portal/portals/callisto.portal
[portal]
DBusName=org.freedesktop.impl.portal.desktop.callisto
Interfaces=org.freedesktop.impl.portal.Settings
```

```ini
# /etc/xdg/xdg-desktop-portal/hyprland-portals.conf
# Shadows /usr/share/…/hyprland-portals.conf entirely (only the first file found is read), so restate default.
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=callisto;gtk
org.freedesktop.impl.portal.Secret=gnome-keyring
```

What the backend publishes, at object path `/org/freedesktop/portal/desktop`, interface version 2:

| Key | Type | Value |
|---|---|---|
| `org.freedesktop.appearance` `color-scheme` | `u` | 1 = dark, 2 = light |
| `org.freedesktop.appearance` `accent-color` | `(ddd)` | sRGB 0–1 of `primary` |
| `org.freedesktop.appearance` `contrast` | `u` | 0 or 1 |

It emits `SettingChanged` when these change. Read/ReadAll return nothing for other namespaces, so gtk keeps serving `org.gnome.desktop.interface` keys: font, cursor, icon theme.

xdp 1.20.3's `settings.c` loops over all Settings implementations in order and stops at the first that has the key. **(verify)** with `gdbus call … Settings.ReadOne org.freedesktop.appearance accent-color` after boot.

Consumers:

- **libadwaita ≥ 1.6** snaps the RGB to the nearest of its nine named accents. Trixie has 1.7.6; GNOME 51 Flatpak runtimes are newer.
- **Firefox and Chromium** use it for `accent-color: auto`.
- **Qt 6.8** reads `color-scheme` through the portal.

**Keep the gtk.css path too, read-only.** libadwaita only takes a snapped accent from the portal. The full Material palette (`window_bg_color` and the rest) still needs `~/.config/gtk-4.0/gtk.css`, and Flatpak apps can't read that without an override. Two choices:

| Option | Command | Result |
|---|---|---|
| (a) Default | `flatpak override --system --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/gtk-3.0:ro` | Apps match the wallpaper palette. Costs a read-only config hole that ArchWiki and TingPing advise against. |
| (b) Clean | Portal accent only | Apps use Adwaita surfaces with a Callisto accent |

Recommendation: (a) for the beauty goal, as a Settings toggle ("Colour apps from wallpaper"). See open questions.

### 4. Flatpak

**Remote.** Install `flathub.flatpakrepo` into `/etc/flatpak/remotes.d/` (download it at build time from `https://dl.flathub.org/repo/flathub.flatpakrepo`). Flatpak adds remotes from that directory automatically, so no `remote-add` is needed at runtime.

**Preinstall strategy (flatpak 1.16 has no `preinstall.d`; that is 1.17+):**

```sh
# 010-callisto-setup.hook.chroot — before any install
flatpak config --system --set languages "en"     # N5: ~1.2 GB of Locale extensions → tens of MB
flatpak install --system --noninteractive flathub $(grep -v '^#' /usr/share/callisto/flatpaks.txt)   # one transaction
flatpak update --system --appstream --noninteractive   # offline search in Settings → Apps
```

- **Install in one transaction.** It resolves shared runtimes once, unlike the current per-ref loop.
- **On installed systems,** first boot runs `flatpak config --system --unset languages` (a Calamares `shellprocess` job), so Locale extensions follow the user's language on the next update.
- **Updates:** a system timer `callisto-flatpak-update.timer` (daily, `RandomizedDelaySec=1h`, `ConditionACPower=true`) running `flatpak update --system --noninteractive`. The Settings Apps panel shows the result.
- **Later:** when Callisto moves to flatpak ≥ 1.17, swap this for `/usr/share/flatpak/preinstall.d/*.preinstall` files plus `flatpak preinstall`. That model also respects user uninstalls.

**Runtime discipline.** Each runtime is about 1 GB uncompressed. Choose apps to minimise runtimes: GNOME 51 plus freedesktop 26.08, with Firefox moving off 25.08 soon. Re-check `metadata` `runtime=` for every ref added. The current image carries four platform versions (fd 25.08, fd 26.08, GNOME 51, GNOME 3.28).

**Portals and the interfaces each serves** (from the shipped `.portal` files):

| Backend | Interfaces |
|---|---|
| xdg-desktop-portal-hyprland 1.4.1 | Screenshot, ScreenCast, GlobalShortcuts, InputCapture |
| xdg-desktop-portal-gtk 1.15.3 | FileChooser, AppChooser, Print, Notification (forwards to the shell's `org.freedesktop.Notifications`), Inhibit (hypridle implements `org.freedesktop.ScreenSaver`, so video playback in Flatpaks blocks idle), Access, Account, Email, DynamicLauncher, Lockdown, Settings |
| gnome-keyring 48 | Secret (only once `portals.conf` names it, N2) |
| callisto (settingsd) | Settings: appearance keys |
| xdg-desktop-portal 1.20.3, no backend needed | OpenURI, Documents, Trash, NetworkMonitor, ProxyResolver, MemoryMonitor, PowerProfileMonitor, Camera (PipeWire), GameMode, Realtime |

Not provided by this stack:

- **Background:** no backend here. **(verify)** what happens when apps ask to autostart.
- **Wallpaper:** no backend. Apps can't set the wallpaper.
- **RemoteDesktop:** XDPH doesn't implement it.
- **Location:** GeoClue isn't installed.

**Theming inside the sandbox.**

- **Dark mode and accent** reach Flatpak apps through the portal (above). Nothing else is needed for GTK4, libadwaita, Firefox or Electron.
- **GTK3 apps** only get the named theme if a matching `org.gtk.Gtk3theme.<name>` extension exists. Callisto uses `gtk-theme='Adwaita'`, which is built into the runtimes, so nothing to install. If you switch to adw-gtk3 (not packaged in Debian; ship it from upstream to `/usr/share/themes`), also preinstall `org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark`.
- **Qt apps on the KDE runtime** ignore host qt6ct: the plugin isn't in the runtime. They follow the portal `color-scheme`. For full palette matching, settingsd can emit `~/.config/kdeglobals` and the image can set `--filesystem=xdg-config/kdeglobals:ro`. That is low priority, since no Qt Flatpak is preinstalled.
- **Fonts:** system fonts in `/usr/share/fonts` and `/usr/local/share/fonts` are visible in the sandbox, and the portal publishes `font-name`. Keep the Triton fonts system-wide; they already are.
- **Cursors:** install them system-wide (the sandbox's `XCURSOR_PATH` includes host icon dirs (verify)), set them through gsettings, `XCURSOR_*` and `hyprctl setcursor`. `bibata-cursor-theme 2.0.6` is in trixie if Adwaita's cursor feels dated.
- **Icons:** libadwaita apps use symbolic icons from the runtime. A host icon theme only matters for GTK3 apps and needs an `org.freedesktop.Platform.Icontheme.*` extension.

**Sandbox overrides** (system-wide, minimal):

```sh
flatpak override --system --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/gtk-3.0:ro   # option (a) above
flatpak override --system --env=ELECTRON_OZONE_PLATFORM_HINT=auto   # harmless for non-Electron apps
# Do not add --nosocket=x11 globally; do not use --socket-if (needs flatpak ≥1.17).
```

**deb vs Flatpak:**

| Component | Choice | Reason |
|---|---|---|
| Shell, Settings, greeter, settingsd | deb or image files | They are the OS |
| Terminal (foot) | deb | Needs host shell and PTY; a sandboxed terminal is pointless |
| **File manager** | **deb `nautilus` 48.3**, replacing the 2018 Flatpak (N4) | Host FileManager1 (Flatpak browsers' "Show in folder"), gvfs, udisks, trash on external drives. It hard-depends on `localsearch`: mask `localsearch-3.service` for the user, or set its index to XDG dirs only. Nautilus falls back to plain search without it (verify). |
| Disks (`gnome-disk-utility`), printing (`system-config-printer`), installer (Calamares) | deb | Privileged and host-facing. No official Flatpaks. |
| Browser (Firefox) | Flatpak | Current release, not 140 ESR. Sandboxed. |
| Text editor, image viewer (Loupe), document viewer (`org.gnome.Papers`), calculator, mpv | Flatpak | Sandboxed. Shared GNOME 51 runtime. |
| App store | Flatpak **Bazaar** (`io.github.kolunmi.Bazaar`), or a Settings → Apps panel over `flatpak` CLI or libflatpak | GNOME Software would pull in packagekit and GNOME daemons. Decide in open questions. |

### 5. Modern stack checklist

| Item | Decision | Specifics |
|---|---|---|
| PipeWire / WirePlumber | Keep trixie 1.4.2 / 0.5.8 | Bluetooth codecs present: SBC, aptX, LDAC, LC3, Opus, FastStream, G.722 (no AAC; it needs fdk-aac). Backports offers pipewire 1.6.9 and wireplumber 0.5.12 if a bug forces it; pin them as a set. |
| NetworkManager vs iwd | NM + wpa_supplicant | `apt purge ifupdown`, `systemctl disable NetworkManager-wait-online.service`. Revisit `[device] wifi.backend=iwd` (iwd 3.8 in trixie) after testing enterprise Wi-Fi, hotspot and MAC randomisation. ModemManager stays installed but can be disabled on the live ISO. |
| BlueZ | Add `bluez` (5.82) | `systemctl enable bluetooth.service`. The shell uses `Quickshell.Bluetooth`. Add `bluez-obexd` only if file transfer is wanted. |
| power-profiles-daemon vs tuned-ppd | ppd 0.30 | tuned-ppd 2.25.1 is available as a drop-in later. Add `thermald` on Intel (2.5.9 stable / 2.5.13 bpo). |
| fprintd | Optional package; parallel PAM context in the lock screen | `fprintd`, `libpam-fprintd` 1.94.5. **Don't** let `pam-auth-update` put fprintd into `common-auth` for the greeter: fingerprint login can't unlock gnome-keyring. |
| systemd-oomd | Enable | Debian's package ships `-.slice.d/10-oomd-root-slice-defaults.conf` and `user@.service.d/10-oomd-user-service-defaults.conf`. `systemctl enable systemd-oomd`. `ManagedOOMPreference=avoid` on the shell unit (may be ignored for user-owned cgroups; verify). |
| zram | `systemd-zram-generator` | `/etc/systemd/zram-generator.conf` below, plus sysctl |
| systemd-homed | No | — |
| systemd-boot vs GRUB | GRUB (signed) for now | Debian does sign systemd-boot (`systemd-boot-efi-amd64-signed 257.13`). A Type #1 entry (Debian-signed kernel plus initrd) would work under shim, but Calamares' Debian config and live-build both assume GRUB. Hide the menu: `GRUB_TIMEOUT=0`, `GRUB_TIMEOUT_STYLE=hidden`, `GRUB_RECORDFAIL_TIMEOUT=0`. |
| Secure Boot | Works through Debian's shim → GRUB → kernel chain | Don't rebuild the kernel or GRUB. Out-of-tree modules (NVIDIA) need DKMS plus MOK enrolment (`mokutil`). Live-build: check the ISO boots with SB enabled in QEMU with OVMF Secure Boot vars. |
| dracut vs initramfs-tools | initramfs-tools | `live-boot` depends on it. Debian's kernel team decided to switch the default to dracut during forky; re-evaluate for installed systems then. |
| Plymouth | Add | `plymouth`, `plymouth-themes`. Callisto theme via `plymouth-set-default-theme -R callisto`. Greetd drop-in below. |
| fwupd | Add | Enable `fwupd-refresh.timer`. Settings shows `fwupdmgr get-updates --json`. |
| xdg-user-dirs | Already enabled globally | Keep |
| GeoClue | Optional | Default: sunrise and sunset from the timezone's coordinates (see below) |
| greetd + Quickshell greeter | Yes | See below |
| Lock-screen PAM | `/etc/pam.d/callisto-lock` | See below |
| Secrets | gnome-keyring plus Secret portal | oo7 isn't packaged, so revisit in forky. KWallet: no. |
| dbus-broker | Keep, already active | `dbus.service` points to `dbus-broker.service` on both the system and user bus (checked) |
| seatd | Remove | logind is the seat manager (greetd → pam_systemd). Two seat managers invite libseat backend confusion, especially for the greeter user. |

```ini
# /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
```

```ini
# /etc/sysctl.d/99-callisto-zram.conf  (zram-tuned values used by Fedora/Pop!_OS-style setups)
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

```ini
# /etc/pam.d/callisto-lock  — Quickshell PamContext { config: "callisto-lock" }
#%PAM-1.0
# Unlock only: no pam_nologin, no 3 s faildelay, no session modules, and deliberately
# not @include common-auth (pam-auth-update may insert fprintd there and serialize prompts).
auth     required  pam_unix.so
account  required  pam_unix.so
```

```ini
# /etc/pam.d/callisto-lock-fprint — second PamContext running in parallel; first success unlocks
#%PAM-1.0
auth     required  pam_fprintd.so max-tries=3 timeout=30
account  required  pam_unix.so
```

```ini
# /etc/pam.d/greetd (installed systems) — current file plus env/limits/keyinit
#%PAM-1.0
auth     required  pam_unix.so
auth     optional  pam_gnome_keyring.so
account  required  pam_unix.so
password required  pam_unix.so yescrypt
session  required  pam_loginuid.so
session  required  pam_env.so readenv=1
session  required  pam_env.so readenv=1 envfile=/etc/default/locale
session  required  pam_limits.so
session  optional  pam_keyinit.so force revoke
session  required  pam_unix.so
session  optional  pam_systemd.so
session  optional  pam_gnome_keyring.so auto_start
```

**Live ISO keyring.** Autologin can't unlock a keyring. Seed `~/.local/share/keyrings/login.keyring` with an empty password in `/etc/skel` for the live user only, so apps never show a "create keyring" prompt.

**Greeter.**

```toml
# /etc/greetd/config.toml (installed)
[terminal]
vt = 1
[default_session]
command = "/usr/libexec/callisto/greeter-session"
user = "greeter"
# live ISO additionally has:
# [initial_session]
# command = "/usr/bin/start-callisto"
# user = "user"
```

```sh
#!/bin/sh
# /usr/libexec/callisto/greeter-session — graphical greeter, TTY fallback
Hyprland --config /usr/share/callisto/greeter/hyprland.lua && exit 0
exec tuigreet --time --remember --cmd /usr/bin/start-callisto
```

The greeter's `hyprland.lua` sets no binds, no blur on the background layer, and `misc.disable_hyprland_logo = true`. It starts `qs -p /usr/share/callisto/greeter/greeter.qml` and exits Hyprland when qs exits.

`greeter.qml` follows this flow:

1. `Greetd.createSession(user)`.
2. `respond(password)` on `authMessage`.
3. `readyToLaunch` → `Greetd.launch(["/usr/bin/start-callisto"])`.
4. `launched` → `Qt.quit()`. greetd waits for the greeter to exit before starting the session.

The `greeter` user needs no extra groups: logind grants the seat through `pam_systemd` in `greetd-greeter`, which includes `login`. Remove seatd for this reason.

**Plymouth → greeter handoff.**

```ini
# /etc/systemd/system/greetd.service.d/10-plymouth.conf
[Unit]
After=plymouth-start.service
[Service]
ExecStartPre=-/usr/bin/plymouth quit --retain-splash
```

The packaged greetd unit already orders `After=plymouth-quit-wait.service`. Keeping that ordering means a black gap between splash and greeter. **(verify)** that dropping it is flicker-free on amdgpu, i915 and virtio-gpu.

**Sunrise and sunset without GeoClue.**

1. `timedatectl show -p Timezone --value` gives the zone, e.g. `Europe/Berlin`.
2. Look it up in `/usr/share/zoneinfo/zone1970.tab`, which gives coordinates like `+5230+01322`.
3. `astral.sun.sun()` (`python3-astral`) turns those into sunrise and sunset.

This runs inside settingsd's scheduler: it drives auto dark/light and hyprsunset at those times. It is accurate to the zone's reference city, which is enough for a dark-mode flip, and needs no permission dialog. "Use precise location" is an opt-in that adds `geoclue-2.0` (verify its default Wi-Fi location provider in Debian 2.7.2 before offering it).

### 6. Installer

| Option | Realistic now? | Notes |
|---|---|---|
| **Calamares 3.3.14** (+ `calamares-settings-debian` 13.0.13 as the base to fork) | **Yes — recommended** | Debian's own live images use it. `unpackfs` copies `/run/live/medium/live/filesystem.squashfs`, so preinstalled Flatpaks, fonts and the shell all carry over. See the module list after this table. |
| debian-installer `live-installer` (`--debian-installer live`) | Possible | Text/GTK d-i UI clashes with the product. It does nothing about greetd, the live user or Flatpaks. Good only as a rescue path. |
| Custom (Quickshell UI + `systemd-repart` + `bootctl`/grub-install + `debootstrap`/squashfs copy) | Not for 0.x | The UI is the easy part. Partitioning edge cases (dual-boot, BitLocker, LVM, LUKS) are what Calamares already solved. |
| Image-based: mkosi 25.3 + systemd-repart, A/B with sysupdate | **No on Debian today** | Debian doesn't ship `systemd-sysupdate` (not in the image or the archive), so A/B has no packaged updater. mkosi can build Debian images; it's usable for a VM or test image. |
| ostree (2025.2 in trixie), or RAUC 1.13 | Later (1.x) | Endless OS is a Debian-based ostree OS, so there's precedent. It would change the "apt ships the system" story into "images ship the system". It fits the existing Flatpak-for-apps split. `bootc` isn't packaged. |

**Calamares setup.**

- **Modules:** welcome, locale, keyboard, partition (ext4 or btrfs; LUKS2 optional), users, summary.
- **Exec sequence:** partition, mount, unpackfs, machineid, fstab, locale, keyboard, localecfg, luksbootkeyfile, users, networkcfg, hwclock, services-systemd, `shellprocess@callisto` (greetd config, Flatpak languages unset, remove live keyring), packages (remove: `live-boot live-boot-initramfs-tools live-config live-config-systemd calamares calamares-settings-callisto`), plymouthcfg, initramfscfg, initramfs, grubcfg, bootloader (`efiBootLoader: grub`), removeuser (`user`), umount.

**Calamares caveats.**

- **Its `displaymanager` module rewrites greetd's `default_session.command`** to gtkgreet, tuigreet, ddlm or agreety (read in `src/modules/displaymanager/main.py`, class `DMgreetd`, at v3.3.14). It also creates `greeter` with group `greetd`. **Don't list greetd in that module.** Write `/etc/greetd/config.toml` from `shellprocess@callisto` instead: drop `initial_session` unless the user ticked autologin.
- **Launching on Hyprland:** Calamares needs root and a Wayland connection. The Debian settings launch it through `pkexec`. Verify that `WAYLAND_DISPLAY`/`XDG_RUNTIME_DIR` reach it (hyprpolkitagent must be running). If not, use a wrapper `sudo -E env QT_QPA_PLATFORM=wayland calamares`.

### 7. Performance

**Boot (live ISO and installed).**

- **Trim enabled units (N7):**
  - Remove `ifupdown`.
  - Disable `NetworkManager-wait-online.service`.
  - Remove `seatd`.
  - On the live image, disable `apt-daily.timer` and `apt-daily-upgrade.timer`.
  - Consider `ModemManager` (enable on demand).
- **Measure** with `systemd-analyze critical-chain graphical.target` and `systemd-analyze --user blame` in QEMU via `scripts/test-iso.sh`. Record the numbers in `.isotest/`.
- **squashfs:** zstd level 19 is already set, and decompresses quickly.
- **Smaller ISO means a faster live boot from USB:** fix N4 and N5, which saves roughly 2 GB uncompressed.
- **GRUB:** hidden menu, timeout 0, installed systems only. Keep the live menu visible.

**Shell start-up.**

- The shell no longer waits for `callisto-apply` (tokens are precompiled).
- Heavy panels (clipboard, overview, settings) belong behind `Loader`/`LazyLoader`, as already flagged in `shell-audit.md`.
- The Settings app leaving the shell process removes its 14 panels from shell start-up entirely.
- Replace `Process { command: ["sh","-c","ls /sys/class/backlight | head -1"] }` at start-up with a direct read. No fork on the critical path.
- **Measure:** `journalctl --user -u callisto-shell -o short-monotonic` from unit start to the first frame. Quickshell logs config load timing with `--log-times`.

**Hyprland GPU cost**, from the 0.55 Variables and Performance wiki pages:

- Blur cost scales with `passes`, and the wiki warns that higher passes "will require more strain on the GPU". `new_optimizations` (default true) "will massively improve performance".
- `xray` "will reduce overhead on floating blur significantly". With xray, blurred surfaces sample only the cached wallpaper and background layers instead of re-blurring the windows below every frame.
- `vfr = true` is the default and is "heavily recommended". Don't touch `damage_tracking`.
- The wiki's laptop advice is to disable blur and shadows entirely. The "solid" material does that.

Sane defaults for Callisto:

```lua
hl.config({
    decoration = {
        blur = {
            enabled = true, size = 7, passes = 2,      -- glass; mica = passes 1; solid = enabled false
            new_optimizations = true, xray = true,     -- shell layers sample the cached wallpaper blur
            popups = false, special = false,           -- both expensive, both off
            noise = 0.0117,
        },
        shadow = { enabled = true, range = 18, render_power = 3, color = "rgba(00000055)" },
    },
    misc = {
        vfr = true,
        vrr = 2,                           -- fullscreen-only; vrr = 1 can flicker some panels at desktop
        allow_session_lock_restore = true, -- see §1
    },
    render = { direct_scanout = 2 },       -- auto: only for content-type "game"
})

-- Shadows only where they are visible: zero-gap tiled windows overlap their neighbours' shadows.
hl.window_rule({ match = { float = false }, no_shadow = true })

-- Per-surface layer rules instead of one rule for every quickshell surface (audit: wallpaper layer
-- was being blurred). Give each Triton window a WlrLayershell.namespace.
hl.layer_rule({ match = { namespace = "^triton-(bar|panel|launcher|osd)$" }, blur = true, ignore_alpha = 0.05, xray = true })
hl.layer_rule({ match = { namespace = "^triton-desktop$" }, no_anim = true })   -- opaque: no blur
```

- **Glass that should show the windows behind it** (for example a launcher over a busy window) can turn xray off on that one namespace. Each such surface then pays a full blur every frame it's visible.
- **On llvmpipe** (QEMU without virgl), settingsd should force the solid material when `systemd-detect-virt` reports a VM *and* `GL_RENDERER` is llvmpipe. That keeps the CI and VM experience usable.

---

## (d) Prioritized migration list

P0 = correctness or security, do first. P1 = latency and architecture. P2 = polish.

| # | Pri | Change | Fixes | Files / units |
|---|---|---|---|---|
| 1 | P0 | Stop `pkill -HUP hypridle`: regenerate the config and run `systemctl --user try-restart hypridle.service`, or skip it when the config is unchanged | N1 (idle and lock-before-sleep silently die) | `scripts/engine/callisto-apply` |
| 2 | P0 | Add `/etc/xdg/xdg-desktop-portal/hyprland-portals.conf` with `Secret=gnome-keyring` (and later `Settings=callisto;gtk`) | N2 | `includes.chroot/etc/xdg/xdg-desktop-portal/` |
| 3 | P0 | Dedicated `callisto-lock` PAM stack; `PamContext.config: "callisto-lock"` | "Lock uses login PAM", N6 | `includes.chroot/etc/pam.d/`, `services/LockState.qml` |
| 4 | P0 | Clipboard: `callisto-clipboard.service` running `wl-paste --watch clip-store` → `cliphist`; skip `x-kde-passwordManagerHint`; delete `callisto-clipwatch` and its `exec_cmd` | "Python per copy, stores password-manager copies" | new unit and `/usr/libexec/callisto/clip-store`; `ClipboardState.qml` reads `cliphist list` |
| 5 | P0 | Add `bluez`; enable `bluetooth.service` | N3 | `callisto.list.chroot`, hook |
| 6 | P0 | Atomic store writes (stopgap until settingsd): write to a temp file in the same dir and `mv`, i.e. `sh -c 'umask 077; d=$HOME/.config/callisto; mkdir -p "$d" && cat > "$d/.settings.json.tmp" && mv -f "$d/.settings.json.tmp" "$d/settings.json"'` | "Store written non-atomically" | `services/SettingsService.qml` |
| 7 | P1 | Keybinds → `GlobalShortcut` + `hl.dsp.global("callisto:…")`; media keys exec'd without `uwsm app`; Super+Return → `uwsm-app`; PipeWire observer for the OSD | "Each keypress creates a systemd unit"; audit C14 | `configs/hypr/hyprland.lua`, `shell.qml` |
| 8 | P1 | Shell as `callisto-shell.service`; remove `hl.on("hyprland.start")` execs; `allow_session_lock_restore` and a lock marker; shell launches apps through `uwsm-app` | Restart-on-crash; apps dying with the shell | new unit, hook `--global enable`, `hyprland.lua`, `LockState.qml`, launcher |
| 9 | P1 | `callisto-settingsd`: socket-activated daemon, single writer, debounce, appliers by domain, Gio for gsettings, scheduler for auto mode and night light | "callisto-apply re-runs everything"; auto-flip spawning | `scripts/engine/` → `/usr/libexec/callisto/settingsd`, units, `SettingsService.qml` (socket), remove the shell `autoFlipProc` |
| 10 | P1 | Power profile set directly by the shell (`PowerProfiles`); drop `power.profile` from the engine | Python `powerprofilesctl` per change | Settings power panel |
| 11 | P1 | Precompile tokens into `/etc/skel` at build; simplify `start-callisto` (drop the apply pre-step and `WLR_*`) | Start-up ordering; N8 | hook, `scripts/start-callisto` |
| 12 | P1 | Settings app as a separate `qs -n -p …/settings-app.qml` instance with `org.callisto.Settings.desktop`; the shell's `settings` shortcut runs `uwsm-app -- org.callisto.Settings.desktop` | "Shell and Settings in the same process" | new entry QML, desktop file, `SettingsAppState` |
| 13 | P1 | Flatpak: drop `org.gnome.Nautilus` (use the deb and mask localsearch); `flatpak config --set languages en`; one-transaction install; `remotes.d`; appstream refresh | N4, N5 (≈2 GB) | `callisto.flatpaks.txt`, `callisto.list.chroot`, hook |
| 14 | P1 | Boot trim: remove ifupdown and seatd; disable wait-online and the apt timers on the live image; add zram and oomd | N7, memory on live ISO | package list, hook, `/etc/systemd/zram-generator.conf` |
| 15 | P1 | Hyprland GPU defaults (passes 2, xray, no shadows on tiled windows, vrr 2, per-namespace layer rules) | GPU cost; audit item on blurring the wallpaper layer | `hyprland.lua`, emitter in the engine, Triton `WlrLayershell.namespace`s |
| 16 | P2 | Portal Settings backend in settingsd (accent-color, color-scheme, contrast) plus the optional `gtk-4.0:ro` override toggle | App accent consistency | settingsd, `callisto.portal`, D-Bus service file |
| 17 | P2 | Quickshell greeter on greetd with tuigreet fallback; Calamares with `shellprocess@callisto` for greetd; live autologin only on the ISO | "Autologin + tuigreet; no installer path" | `/usr/share/callisto/greeter/`, `configs/greetd/`, Calamares settings package |
| 18 | P2 | Plymouth theme plus greetd `--retain-splash` drop-in; fwupd and its refresh timer | Polish, firmware | package list, includes |
| 19 | P2 | Optional fingerprint unlock (parallel `PamContext`); in-shell polkit agent replacing hyprpolkitagent | Polish, consistency | `LockState.qml`, new `PolkitAgent.qml` |
| 20 | P2 | Timezone-based sunrise for auto mode and night light; GeoClue opt-in | "Auto light/dark is 07–19" | settingsd scheduler |

---

## (e) Open questions for the owner

1. **Flatpak app colours:**
   - (a) The read-only `xdg-config/gtk-4.0` override, so GTK and libadwaita apps take the full wallpaper palette and match the shell.
   - (b) Portal accent only, so apps stay Adwaita-grey with a Callisto accent: cleaner sandbox, less "designed".
   - Recommendation is (a) behind a Settings toggle. Default on?
2. **Glass realism vs GPU:** should shell glass show *windows* behind it (xray off: costlier, "true" glass) or only the wallpaper (xray on: cheap, steady frame time)? The recommendation is xray on for the bar and panels, possibly off for the launcher only.
3. **File manager:** a Nautilus .deb (pulls in `localsearch`, to be masked), or another manager? Nautilus fits the GNOME and libadwaita app set. The Flathub build isn't viable.
4. **App store:** Bazaar (a Flatpak), or an "Apps" panel in Settings built on `flatpak` and libflatpak? The panel is more on-brand but takes more work.
5. **Installed-system default:** greeter with password (recommended), or offer autologin in Calamares? Autologin breaks keyring unlock.
6. **Update model for 1.x:** stay apt plus backports overlay, or plan an ostree image (Endless OS model)? This decides whether systemd-boot and UKIs are worth pursuing.
7. **Backports appetite:** move to the backports kernel 7.3.4, Mesa 26.1 and PipeWire 1.6.9 for newer hardware, or stay on trixie stable for those and use backports only for the Hypr stack? Newer laptops (Lunar Lake, RDNA4) want the newer kernel and Mesa.
8. **Fingerprint:** in scope for 0.x? It affects PAM design (parallel contexts) and the lock UI.
9. **Precise location:** is GeoClue ever wanted, or is timezone-accurate sunrise enough?
10. **Polkit look:** is the hyprtoolkit-styled hyprpolkitagent dialog acceptable for 0.1, or is a Triton-styled in-shell agent a 0.1 requirement?

---

## Sources

- Quickshell v0.3.0 GlobalShortcut — https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/GlobalShortcut/
- Hyprland 0.55 wiki: Binds (global dispatcher, Lua bind flags) — https://wiki.hypr.land/0.55.0/Configuring/Basics/Binds/ ; Variables (blur, shadow, vfr, allow_session_lock_restore, direct_scanout) — https://wiki.hypr.land/0.55.0/Configuring/Basics/Variables/ ; Performance — https://wiki.hypr.land/0.55.0/Configuring/Advanced-and-Cool/Performance/ ; Window rules (`no_shadow`, `xray`, layer rules) — https://wiki.hypr.land/0.55.0/Configuring/Basics/Window-Rules/
- uwsm v0.26.7 README (slices, `uwsm-app`/app-daemon, short-lived commands in the compositor unit) — https://github.com/Vladimir-csp/uwsm/blob/v0.26.7/README.md
- hypridle v0.1.8 source (no signal handling) — https://github.com/hyprwm/hypridle/tree/v0.1.8/src
- xdg-desktop-portal 1.20.3: `src/settings.c` (Settings across multiple backends), `data/org.freedesktop.portal.Settings.xml` (appearance keys) — https://github.com/flatpak/xdg-desktop-portal/tree/1.20.3 ; `portals.conf(5)` (first file wins, `[preferred]`)
- Calamares v3.3.14 `src/modules/displaymanager/main.py` (`DMgreetd`) — https://github.com/calamares/calamares/blob/v3.3.14/src/modules/displaymanager/main.py
- flatpak-preinstall(1) (1.17+) — https://man7.org/linux/man-pages/man1/flatpak-preinstall.1.html ; Phoronix on Flatpak 1.17 — https://phoronix.com/news/Flatpak-1.17
- Debian kernel team on the dracut switch in forky — https://lists.debian.org/debian-kernel/2025/09/msg00122.html , https://lists.debian.org/debian-kernel/2026/01/msg00202.html
- Debian archive (madison) for every version quoted — https://api.ftp-master.debian.org/madison ; file lists for `systemd-oomd` and `systemd-zram-generator` — https://packages.debian.org/trixie/amd64/systemd-oomd/filelist
- Flathub API for `org.gnome.Nautilus` status — https://flathub.org/api/v2/summary/org.gnome.Nautilus
- Local evidence from the last build: `live-build/chroot.packages.install`; `live-build/chroot/usr/lib/systemd/user/*`; `…/usr/share/xdg-desktop-portal/`; `…/etc/pam.d/`; `…/usr/lib/x86_64-linux-gnu/qt6/qml/Quickshell/**.qmltypes`; `wl-paste(1)` (`CLIPBOARD_STATE` is never set to `sensitive`)
