# Shell Architecture Research — Quickshell on Hyprland for Callisto/triton-bar

Date: 2026-11-26. Research notes for building triton-bar (from-scratch QML status bar)
on a Debian 13 live ISO. Uncertainties are flagged with **[?]**.

---

## 1. How real Quickshell projects are structured

### The big two reference configs

**end-4/dots-hyprland ("illogical-impulse")** — the canonical large Quickshell config:

```
~/.config/quickshell/ii/
  shell.qml              # ShellRoot entry point
  settings.qml           # separate settings app (ApplicationWindow, own process)
  GlobalStates.qml       # singleton: central UI-state bus (sidebarOpen, overviewOpen...)
  panelFamilies/
    IllogicalImpulseFamily.qml   # manifest of panels for the "ii" look
    WaffleFamily.qml             # alternate layout, runtime-switchable
  modules/
    common/        # Config.qml, Appearance.qml, Directories.qml, widgets/
    ii/            # ii-specific panels (bar, sidebars, dock, overview...)
    waffle/        # waffle-specific panels
    settings/      # settings app pages
  services/        # Audio, Battery, Network, Notifications, MprisController...
```

Key patterns worth copying into triton-bar:

- **`shell.qml` is a thin `ShellRoot`** that just loads shared services and the panel
  family via `LazyLoader`/`PanelLoader`. Panels are instantiated per-screen with
  `Variants`/`Scope` or `PanelLoader` wrappers, gated on `Config.ready`.
- **Services are QML singletons** (`pragma Singleton` + a `qmldir` file or the newer
  Quickshell `Singleton` type) that wrap D-Bus/PipeWire/IPC in reactive properties.
  Widgets never touch IPC directly — they bind to service properties.
- **Config is JSON-backed**: `FileView` + `JsonAdapter` with debounced write timers
  (~50–75 ms) so sliders don't thrash the disk. State that survives restarts but
  isn't user config goes in a separate `Persistent.qml`.
- **`GlobalStates.qml` as a central state bus** — visibility of every panel is a
  property here, toggled by `IpcHandler`s and `GlobalShortcut`s so external scripts
  (`qs ipc call ...`) and Hyprland keybinds can drive the shell.
- Imports use the 0.2+ root-relative syntax: `import qs.modules.common`, where `qs`
  is the config root. A `.qmlls.ini` file in the shell root auto-generates LSP config.

Sources: [deepwiki end-4 Quickshell UI system](https://deepwiki.com/end-4/dots-hyprland/3-quickshell-ui-system),
[ii-vynx AGENTS.md](https://github.com/vaguesyntax/ii-vynx/blob/main/AGENTS.md),
[deepwiki end4-pC architecture](https://deepwiki.com/pctrade/end4-pC/1.2-architecture-and-core-singletons)

**caelestia-shell** — the other major config. Notable differences:

- Ships as a CMake-installed package (its own QML plugin), cloned into
  `~/.config/quickshell/caelestia`.
- Launched as `qs -c caelestia` or via wrapper `caelestia shell -d`.
- Config in `~/.config/caelestia/shell.json` with per-monitor overrides in
  `~/.config/caelestia/monitors/<name>/shell.json`.
- Uses Hyprland **D-Bus global shortcuts** for keybinds rather than compositor-side exec.

Source: [caelestia-dots/shell README](https://github.com/caelestia-dots/shell)

### How the shell is loaded: `-p` vs `~/.config/quickshell`

Quickshell's config resolution (documented in the usage guide):

- `qs` with no arguments loads `~/.config/quickshell/shell.qml` (the default config root).
- `qs -p <path>` / `--path` loads a config from an arbitrary directory or file.
- `qs -c <name>` loads the *named* config `~/.config/quickshell/<name>/shell.qml` —
  this is why end-4 runs `qs -c ii` and caelestia `qs -c caelestia`. Multiple named
  configs can coexist.
- Each config root gets a **shell id**; since 0.3.0 config paths are no longer
  canonicalized, so symlinked config dirs change the shell id (matters if the live
  ISO symlinks `$HOME/.config` content — prefer bind-mounting or real files).
- `-d` detaches (daemonize). `qs kill` / `qs ipc` operate on running instances.

**Recommendation for Callisto:** ship the bar as a real directory at
`~/.config/quickshell/triton/` (or `/etc/skel` seeding it) and launch with
`qs -c triton -d` from Hyprland's `exec-once`. This keeps the default
`~/.config/quickshell/shell.qml` slot free for user experimentation and avoids
symlinked-path shell-id churn.

### Version situation — what Debian actually ships

- Quickshell is **not in Debian 13 (trixie) main**, but **is in trixie-backports as
  `quickshell 0.3.0-1~bpo13+1`** (accepted 2026-06-03). Testing/sid carry 0.3.2.
  Source: [tracker.debian.org/pkg/quickshell](https://tracker.debian.org/pkg/quickshell),
  [madison](https://qa.debian.org/madison.php?package=quickshell)
- Upstream API baseline: **0.3.0 is what you must target.** Key version facts from
  the [upstream changelog](https://quickshell.org/changelog/):
  - 0.1.0 → initial release. Docs you find quoting `quickshell.outfoxxed.me/docs/v0.1.0`
    are old but the core PanelWindow/Hyprland/Pipewire/Process APIs are unchanged.
  - 0.2.0 → **breaking**: files outside the shell dir can't be referenced by relative
    paths; `PanelWindow`'s Auto exclusion mode adds a zone for single-anchor panels;
    `import qs.*` root-relative imports introduced (replaces `root:/`); added
    `Quickshell.execDetached()`, `Process.exec()`, `HyprlandToplevel`.
  - 0.3.0 → polkit agent, idle inhibitors, ext-workspace `WindowManager` module,
    ext-background-effect blur, network module, **Hyprland lua config support**,
    plus many PipeWire volume fixes. `HyprlandWorkspaces`-style API does **not**
    exist — the workspace API is the `Hyprland` singleton (below) in every version
    including 0.3.x.
- The docs site is versioned per-release (`/docs/v0.3.0/...`); always pin to v0.3.0
  when reading for this project.

## 2. Exact QML APIs (verified against upstream type docs)

All stable across 0.1–0.3 unless noted. Sources are the versioned type docs.

### PanelWindow / layer shell

`import Quickshell` — [PanelWindow docs](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell/PanelWindow)

```qml
PanelWindow {
  anchors { top: true; left: true; right: true }
  implicitHeight: 36          // height is your own; width forced by opposite anchors
  exclusiveZone: 36           // reserve space so windows don't overlap the bar
  // or: exclusionMode: ExclusionMode.Auto / Normal / Ignore
  margins { top: 4 }          // offset from screen edge (only on anchored edges)
  color: "transparent"
}
```

- `anchors` — attach to screen edges. Opposite anchors force the corresponding
  dimension to screen size.
- `exclusiveZone` (int) — space reserved relative to anchors; setting it implies
  `ExclusionMode.Normal`. **Needs 1 or 3 anchors to take effect.** In 0.2+, margins
  opposite the anchor edge are added into the exclusion zone, and Auto mode reserves
  space for single-anchor panels.
- `aboveWindows` (default true) ↔ `WlrLayershell.layer` (top vs bottom).
- `focusable` ↔ `WlrLayershell.keyboardFocus` — leave false for a bar, needed for
  launchers/popups that take keyboard input.
- Per-screen: wrap in `Variants`/`Scope` with `model: Quickshell.screens` (or use
  `screen` property) — the standard bar-per-monitor pattern in both big configs.
- For finer control there's `Quickshell.Wayland/WlrLayershell` as an attached object
  (namespace, layer, keyboardFocus). **The layer-shell namespace defaults to the
  window's `screen`-derived name; Hyprland `layerrule` matching uses the namespace
  shown in `hyprctl layers`** — for Quickshell 0.3 the namespace is typically
  `quickshell` (or per-window if set). **[?] Verify actual default namespace with
  `hyprctl layers` on the live image; some versions report `quickshell` for all
  panels, which makes per-panel layerrules impossible without distinct namespaces.**

### Hyprland workspaces & dispatch

`import Quickshell.Hyprland` — the **`Hyprland` singleton**,
[docs](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell.Hyprland/Hyprland):

- `Hyprland.workspaces` — `ObjectModel<HyprlandWorkspace>`, all workspaces sorted by
  id (named/special workspaces have negative ids and sort first). Usable directly as
  a `Repeater` model.
- `Hyprland.focusedWorkspace`, `Hyprland.focusedMonitor`, `Hyprland.monitors`.
- `Hyprland.dispatch("workspace 3")` — executes any dispatcher.
- `Hyprland.refreshWorkspaces()` / `refreshMonitors()` — needed because some changes
  don't emit events.
- `Hyprland.rawEvent(HyprlandEvent)` — signal for every socket2 event (`workspace`,
  `activewindow`, ...); `HyprlandMonitor`/`HyprlandWorkspace` objects have:
  - workspace: `id`, `name`, `active` (active on its monitor), `focused` (active *and*
    monitor focused — use this for the highlighted pill), `hasFullscreen`, `monitor`,
    `lastIpcObject`, and method **`activate()`** (equivalent to dispatching
    `workspace <id>`; 0.2 fixed named/special workspace handling).
- 0.2+ adds `HyprlandToplevel` for window-level data if the bar wants active-window titles.

Typical bar widget pattern (as in both big configs):

```qml
Repeater {
  model: Hyprland.workspaces
  delegate: WorkspacePill {
    required property HyprlandWorkspace modelData
    active: modelData.focused
    onClicked: modelData.activate()
  }
}
```

### SystemClock

`import Quickshell` — [docs](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell/SystemClock):

```qml
SystemClock { id: clock; precision: SystemClock.Seconds }  // Minutes/Hours/Seconds
Text { text: Qt.formatDateTime(clock.date, "hh:mm") }
```

- Updates within ±50 ms of the wall clock edge. **Use `clock.date`, never construct
  `new Date()` in a binding** — it won't re-evaluate.
- `enabled: false` pauses updates (set false when the bar is hidden to save wakeups).

### PipeWire volume

`import Quickshell.Services.Pipewire` —
[Pipewire singleton](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell.Services.Pipewire/Pipewire),
[PwNode](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell.Services.Pipewire/PwNode):

```qml
PwObjectTracker { objects: [Pipewire.defaultAudioSink] }   // REQUIRED to bind the node

readonly property var sink: Pipewire.defaultAudioSink
// sink.audio.volume   (0.0–1.0+, writable)
// sink.audio.muted    (writable)
// sink.description / sink.nickname  for display
// Pipewire.defaultAudioSource for mic; preferredDefaultAudioSink is writable to change default
```

Critical gotchas:

- **`PwObjectTracker` binding is mandatory** — node properties (`audio.volume`,
  `properties`) are invalid/empty for unbound nodes. Every real config wraps the
  default sink/source in a tracker.
- `Pipewire.defaultAudioSink` can be **null** (no audio hardware — QEMU without an
  audio device, or during device transitions). Bind defensively:
  `sink && sink.audio ? sink.audio.volume : 0` and hide/disable the widget when null.
- `Pipewire.ready` is false until initial sync; don't render stale state.
- 0.3.0 fixed many volume-write bugs (pro-audio mode, bluez, missing volume steps);
  the backported Debian build includes these.

### Launching processes

`import Quickshell.Io` — [Process docs](https://quickshell.outfoxxed.me/docs/v0.1.0/types/Quickshell.Io/Process):

```qml
Process {
  command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]  // argv list, NO shell
  running: true                       // start; setting false sends SIGTERM
  stdout: StdioCollector { onStreamFinished: ... }
  onExited: (code, status) => { ... }
}
// one-shots: prefer execDetached — no object lifecycle, survives shell reload:
Quickshell.execDetached(["foot"]);        // 0.2+
proc.startDetached()                       // per-Process detached launch
```

- `command` is argv, not a shell string. Use `["sh", "-c", "..."]` if you need a shell.
- Non-detached processes are **killed when quickshell exits or reloads** — always use
  detached execution for launching apps from the bar.

## 3. Hyprland layer rules interacting with Quickshell

### Version landscape

- **Hyprland is not in trixie main at all** (removed from testing pre-release).
  trixie-backports carries **`hyprland 0.55.2+ds-1~bpo13+1`**; unstable is at 0.57.x.
  Sources: [tracker.debian.org/pkg/hyprland](https://tracker.debian.org/pkg/hyprland),
  [linuxiac](https://linuxiac.com/debian-13-stable-users-can-now-install-hyprland-from-backports/),
  [backports overview](https://backports.debian.org/trixie-backports/overview/)
- Since we're at 0.55.x, the **layerrule v2 "match" syntax applies** (introduced in
  the 0.53 config-rewrite along with windowrule v3). The old positional
  `layerrule = blur, waybar` form and bare `ignorezero` are gone.

### Correct syntax for 0.55 (non-lua config)

```conf
# Hyprland 0.53+ layerrule syntax (applies to the 0.55.x in trixie-backports):
layerrule = blur on, ignore_alpha 1, match:namespace rofi
layerrule = blur on, ignore_alpha 0.5, match:namespace quickshell
layerrule = animation none, match:namespace selection
```

Facts assembled from
[hyprwm/Hyprland discussion #12798](https://github.com/hyprwm/Hyprland/discussions/12798),
[hyprlang-rs docs](https://github.com/spinualexandru/hyprlang-rs),
[HyDE issue #1569](https://github.com/HyDE-Project/HyDE/issues/1569),
[0.53 migration gist](https://gist.github.com/robertogogoni/138f2ade1269ce0a6433fba367786d3b):

- `blur` is a **boolean** written `blur on` (or `blur true`).
- `ignorezero` and `ignorealpha` merged into **`ignore_alpha <float 0..1>`** — the
  alpha threshold below which pixels are ignored by blur. Old `ignorezero` ≈
  `ignore_alpha 0` behavior changed semantics; end-4's own PR
  ([#2477](https://github.com/hyprwm/Hyprland/pull/2477)) is what made it a float.
- Namespace matching is **mandatory** via `match:namespace <regex>` — a layerrule
  without it errors ("missing value").
- Effects available in 0.53+: `blur`, `blur_popups`, `ignore_alpha`, `animation`,
  `no_anim`, `xray`, `dim_around`, `order`, `above_lock` (2 = interactive on lock),
  `no_screen_share`. [hyprland-wiki layer-rules](https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/rules/layer-rules.md)
- Note the wiki's *current* examples are in **lua** (`hl.layer_rule({...})`) because
  0.57 lua config landed — **do not copy those**; 0.55 uses the flat `layerrule =`
  lines above. **[?] The flat `key = value` match-syntax form for 0.55 is attested
  in discussions/migration scripts but I did not find a versioned official wiki page
  for 0.55; test on the live image and iterate with `hyprctl reload` error output.**
- Blur must also be enabled in `decoration { blur { enabled = true ... } }` and some
  layers are client-controlled — Quickshell surfaces are plain translucent layer
  surfaces, so compositor-side blur works fine if the bar background is translucent
  (alpha < 1). Quickshell 0.3 additionally supports ext-background-effect, so
  compositor layerrules may not even be needed for blur on 0.55 **if** the compositor
  implements the protocol **[?] Hyprland support for ext-background-effect in 0.55
  is unverified — safest path is layerrules**.

For a bar, typical needs: `blur on` for translucent bar background, and
`ignore_alpha <small>` so fully transparent click-through regions don't blur.

## 4. greetd autologin for a live system

### How it's wired

`/etc/greetd/config.toml` (TOML), documented in
[greetd(5)](https://manpages.debian.org/bookworm/greetd/greetd.5.en.html) and the
[ArchWiki greetd page](https://wiki.archlinux.org/title/Greetd):

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd /usr/local/bin/callisto-session"
user = "greeter"

[initial_session]
command = "/usr/local/bin/callisto-session"
user = "live"
```

Semantics that matter for a live ISO:

- **`[initial_session]` runs exactly once per boot** — greetd creates a runfile
  (`general.runfile`, default under `/run`) after the first start; on logout or
  greeter exit it falls through to `[default_session]`. This is precisely the live-ISO
  pattern: boot straight into the desktop, but if the user logs out they get a real
  greeter instead of an autologin loop. Confirmed by real-world usage: NixOS/Arch
  configs, EndeavourOS's calamares module which copies `initial_session` from the live
  ISO and *deletes* it on install.
- `command` is run by `sh` and may use shell syntax. `user` is required for
  initial_session.
- greetd itself must be enabled: `systemctl enable greetd.service` (it provides
  `display-manager.service` via symlink).
- The greeter (`tuigreet`) runs as the unprivileged `greeter` user. greetd and
  tuigreet are both packaged in Debian trixie main.

### What the session wrapper must export

Real distros (Manjaro-sway, Fedora Sway spin, the NixOS configs above) wrap the
compositor in a small script because the greeter/autologin environment is bare.
The wrapper should:

```sh
#!/bin/sh
# /usr/local/bin/callisto-session
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
# IMPORTANT for quickshell/Qt on some setups:
export QT_QPA_PLATFORMTHEME=       # leave unset or qt6ct if desired
# dbus: greetd/PAM usually provides a session bus via pam_systemd user session,
# but belt-and-braces for compositors that don't:
exec dbus-run-session -- Hyprland   # or just `exec Hyprland` if logind user session is confirmed working
```

Notes:

- With systemd-logind (present on Debian live images), `pam_systemd` creates the user
  session, sets `XDG_RUNTIME_DIR`, and starts `user@UID.service`, so the user bus and
  systemd user units are available and `dbus-run-session` is usually unnecessary —
  but it's harmless and is the standard insurance on minimal images. **[?] Verify on
  the actual image whether `systemctl --user` units activate without it; redundant
  dbus-run-session inside a logind session can break bus sharing with user services,
  so prefer relying on logind if verified.** Actually — caveat: nesting
  `dbus-run-session` creates a *new* bus, so PipeWire started on the systemd user bus
  and clients on the nested bus can mismatch. Recommend: rely on logind+PAM, no
  dbus-run-session, and verify.
- `tuigreet` is the standard TUI greeter (used by Manjaro-sway and many live spins);
  alternatives: `agreety` (bundled, plain), or cage+greetd-gtkgreet / ReGreet for
  graphical.

## 5. PipeWire/WirePlumber on live ISOs, and graceful degradation

### What must be running in the session

Volume control via Quickshell's Pipewire service requires, per user session:

1. **`pipewire`** — the daemon. On Debian it's socket-activated as a **systemd user
   unit** (`pipewire.socket`), so `systemctl --user` must be functional, i.e. the
   logind user session must exist (see §4 — no double dbus-run-session).
2. **`wireplumber`** — the session manager. **Without it PipeWire does no device
   routing and `Pipewire.defaultAudioSink` will stay null.** Debian package
   `wireplumber` ships `wireplumber.service` user unit, usually pulled in by
   `pipewire.service` ordering/dependency or enabled globally.
   Sources: [ArchWiki PipeWire](https://wiki.archlinux.org/title/PipeWire),
   [wireplumber(1)](https://pipewire.pages.freedesktop.org/wireplumber/man/wireplumber.html).
3. **`pipewire-pulse`** — only needed for PulseAudio *clients* (pactl, some apps);
   Quickshell talks native PipeWire and does **not** need it. Still ship it for app
   compatibility.

Practical checklist for the ISO: user units enabled in the global user preset
(`/usr/lib/systemd/user/`), `XDG_RUNTIME_DIR` present (logind), user in no special
groups needed on systemd systems (logind ACLs handle device access; the `audio`
group is a non-systemd workaround). On a live ISO all of this is tmpfs-backed and
just needs the packages plus correct session activation.

QEMU testing note: pass an audio device (`-device intel-hda -device hda-duplex` with
`-audiodev`) or PipeWire will have zero sinks — useful for testing the null path, but
don't mistake it for a bug.

### Graceful degradation patterns (how big shells handle it)

- **No battery / QEMU**: end-4 and caelestia both gate the battery widget on
  whether UPower reports a battery device — the service singleton exposes
  e.g. `Battery.isLaptopBattery`/`available` and the bar's loader simply doesn't
  instantiate the widget (`PanelLoader { extraCondition: Battery.available }`).
  UPower on a battery-less VM has no devices at all, so: null-check, don't render.
  Quickshell 0.3 has a full `Quickshell.Services.UPower` module — use
  `UPower.displayDevice` and check `type == UPowerDeviceType.Battery` + state.
  **[?] Exact property shape of `UPower.displayDevice` when no battery exists
  (null vs a "line power" device) should be verified; defensively treat
  non-battery as hidden.**
- **No audio sink**: as in §2, `Pipewire.defaultAudioSink` is null → hide or grey
  out the volume widget; never write volume to null. Also handle transient nulls
  during device switches (documented upstream).
- **No network / offline**: NM absent in some QEMU runs; the 0.3 Networking module
  has `Networking.backend` state for this.
- General pattern worth copying: **every optional hardware feature gets a
  service-singleton boolean (`available`/`ready`), and panel components are wrapped
  in lazy loaders conditioned on it** — the shell never crashes or shows broken
  widgets in a VM.

---

## Open uncertainties to verify on the actual image **[?]**

1. Actual layer-shell namespace(s) Quickshell 0.3.0 emits → `hyprctl layers` output;
   whether per-panel namespaces can be set for distinct layerrules.
2. Exact accepted flat-config layerrule spelling in Hyprland 0.55.2 (match syntax is
   confirmed in principle; test `hyprctl reload` errors).
3. Whether Hyprland 0.55 implements ext-background-effect well enough to skip
   layerrule blur entirely.
4. Whether the Debian live session needs `dbus-run-session` or logind alone provides
   a working user bus + `systemctl --user` (prefer the latter).
5. `UPower.displayDevice` behavior with zero batteries.
6. quickshell 0.3.0 in backports vs 0.3.2 in sid: if the ISO build can pull from
   backports only, target 0.3.0 exactly; mixing in sid Qt6 libraries on trixie is
   not viable, so stick with backports.
