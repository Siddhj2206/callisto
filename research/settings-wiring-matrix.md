# Settings Wiring Matrix

Audited 2026-11-27. Sources: all 14 panels in `shell/triton/settings/`, `SettingRow.qml`, `PanelHeader.qml`, `TritonSwitch`/`TritonSlider`/`TritonChip` in `shell/triton/components/`, `shell/triton/services/SettingsService.qml`, and the engine consumer `scripts/engine/callisto-apply`. Cross-checked against shell consumers (`Desktop.qml`, `bar/Bar.qml`, `bar/Clock.qml`, `wallpaper/WallpaperWindow.qml`, `services/NotificationState.qml`) and the seed store `configs/callisto/default-settings.json`.

## Legend

- **WIRED** — control writes a store key the engine (or a live shell consumer) actually reads.
- **STORE-ONLY** — writes/reads the store, but nothing downstream consumes the key. Dead end.
- **PLACEBO** — hardcoded value, no write at all. Inert control.
- **UNWIRED-SIGNAL** — emits a signal nobody handles.

## Engine-consumed keys (ground truth)

`callisto-apply` reads exactly these store keys:

| Key | Consumed for |
|---|---|
| `appearance.accent` | matugen scheme resolution (`wallpaper` / named seed / `#hex`) |
| `appearance.wallpaper` | matugen image extraction path |
| `appearance.mode` | `gsettings org.gnome.desktop.interface color-scheme` (only `"light"` matters; `"auto"` treated as dark) |
| `windows.focusFollowsMouse` | `input:follow_mouse` in lua config + hyprctl keyword push |
| `input.keyboardLayout` | `kb_layout` + hyprctl push |
| `input.repeatRate` | `input:repeat_rate` (int, keys/sec) + hyprctl push |
| `input.repeatDelay` | `input:repeat_delay` (int, ms) + hyprctl push |
| `input.naturalScroll` | `touchpad natural_scroll` + hyprctl push |
| `input.tapToClick` | `touchpad tap-to-click` + hyprctl push |
| `power.profile` | `powerprofilesctl set` (validated against power-saver/balanced/performance) |

Live shell consumers (not engine, but real wiring targets):

| Key | Consumer |
|---|---|
| `shell.barMode` | `bar/Bar.qml` visibility (`pinned`/`hidden`/`edge`) |
| `shell.clockFormat` | `bar/Clock.qml` 12h/24h |
| `appearance.wallpaper` / `appearance.wallpaperKind` | `Desktop.qml`, `wallpaper/WallpaperWindow.qml` (written by wallpaper picker, not the settings UI) |

---

## Panel-by-panel matrix

### AppearancePanel.qml

The most important panel is the least wired. All controls mutate **local component properties** (`root.mode`, `root.accent`, `root.contrast`, `root.material`) initialized to hardcoded literals — they neither read nor write the store. Signals are declared (`modePicked`, `accentPicked`, `contrastMoved`, `materialPicked`, `transparencyToggled`, `tintedToggled`) but `SettingsWindow.qml` only connects `onWallpaperBrowse`. Every control below is **UNWIRED-SIGNAL** — clicks animate locally and are forgotten when the panel's Loader unloads it.

| Row / control | Type | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Wallpaper preview card click | MouseArea | `appearance.wallpaper` (read-only, for preview image) | — (opens Wallpaper picker) | — | WIRED (read side only; the write path is `WallpaperWindow.qml` outside Settings) |
| Mode segment — Dark | segment | local `mode` | signal `modePicked` | `"dark"` | **UNWIRED-SIGNAL** — engine consumes `appearance.mode`! |
| Mode segment — Light | segment | local | signal | `"dark"` | **UNWIRED-SIGNAL** |
| Mode segment — Auto at sunset | segment | local | signal | `"dark"` | **UNWIRED-SIGNAL** — engine has no `auto` handling at all |
| Accent swatch ×5 (Planet/Hull/Rock/Shadow/Haze) | WaveShape chips | local `accent` | signal `accentPicked` | `"wallpaper"` | **UNWIRED-SIGNAL** — engine consumes `appearance.accent`; seeds match ACCENT_SEEDS exactly |
| Accent "Custom" circle | circle + MouseArea | — | emits `accentPicked("wallpaper")` (!) | — | **UNWIRED-SIGNAL** + logic defect: "Custom" writes `wallpaper`, no custom-color path exists |
| Contrast slider | TritonSlider (continuous, not stops) | local `contrast` | signal `contrastMoved` | `0.0` | **UNWIRED-SIGNAL** — engine never reads `appearance.contrast` anyway (double dead end) |
| Material cards — Solid/Mica/Glass | cards | local `material` | signal `materialPicked` | `"mica"` | **UNWIRED-SIGNAL** — engine never reads `appearance.material` (double dead end) |
| Supporting text hardcodes | — | — | — | — | readout says "Standard", never updates with contrast value |

The panel comment claims "Everything applies live — edits go straight to SettingsService". Nothing does. Additionally `transparency`/`tintedSurfaces` properties and their signals exist but have **no controls at all** in the panel (declared, never rendered).

### BarShellPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Autohide cards — Hidden/Reveal/Pinned | card picker | `shell.barMode` | `shell.barMode` | `"pinned"` | WIRED (shell-side: `bar/Bar.qml` reads it; engine doesn't need to) |
| Reveal edge | none — text row only | — | — | — | **PLACEBO** (no control rendered at all; supporting text is static) |
| Reveal delay | none — text row only | — | — | — | **PLACEBO** (same — no slider, no store key) |
| Reveal on urgent notification | TritonSwitch | `shell.revealOnUrgent` | `shell.revealOnUrgent` | `true` | **STORE-ONLY** — no consumer in shell or engine |
| Show window title | TritonSwitch | `shell.showWindowTitle` | `shell.showWindowTitle` | `true` | **STORE-ONLY** — no consumer |
| Battery as wavy ring | TritonSwitch | `shell.batteryWavyRing` | `shell.batteryWavyRing` | `false` | **STORE-ONLY** — no consumer |
| 24-hour clock | TritonSwitch | `shell.clockFormat` | `shell.clockFormat` | `"24h"` | WIRED (`bar/Clock.qml`) |
| Reduce motion | TritonSwitch | `shell.reduceMotion` | `shell.reduceMotion` | `false` | **STORE-ONLY** — seed store lists it, but nothing in the shell reads it |

### WindowsPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Focus follows mouse | TritonSwitch | `windows.focusFollowsMouse` | same | `true` | WIRED (engine → hyprland `follow_mouse` + live keyword) |
| Center focused column | **none** — row has no control | — | — | — | **PLACEBO** — the board intent is a 3-way segment ("Never/On overflow/Always"); panel ships only the title row. Comment says "Every row is a store-backed switch or segment" — false. No `windows.centerColumn` key exists anywhere. |

### KeyboardPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Keyboard layout | none — static text "English (US)" | — | — | — | **PLACEBO** — engine consumes `input.keyboardLayout` but UI never writes it |
| Key repeat | TritonSwitch | `input.repeat` | `input.repeat` | `true` | **STORE-ONLY** — engine reads `repeatRate`/`repeatDelay` but never `repeat` |
| Repeat rate | TritonSlider, `value: 0.5` hardcoded, **no `onMoved`** | — | — | — | **PLACEBO** — slider inert; engine expects int keys/sec (`input.repeatRate`, default 25), control is normalized 0..1 with no mapping even if wired |
| Repeat delay | TritonSlider, `value: 0.4` hardcoded, no handler | — | — | — | **PLACEBO** — same, engine expects ms int (`input.repeatDelay`, default 400) |

### MousePanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Natural scrolling | TritonSwitch | `input.naturalScroll` | same | `true` | WIRED (engine → hyprland `touchpad.natural_scroll`) |
| Tap to click | TritonSwitch | `input.tapToClick` | same | `true` | WIRED |
| Pointer speed | TritonSlider, `value: 0.5` hardcoded, no handler | — | — | — | **PLACEBO** — no store key (`input.pointerSpeed`?) exists in engine or defaults |

### PowerPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Power profile radios ×3 | radio icons + row MouseArea | `power.profile` | `power.profile` | `"balanced"` | WIRED (engine → `powerprofilesctl set`) |
| Dim screen when idle | TritonSwitch | `power.dimIdle` | `power.dimIdle` | `true` | **STORE-ONLY** — engine never reads it (no idle/dim integration exists yet) |
| Suspend when idle | TritonSwitch | `power.suspendIdle` | `power.suspendIdle` | `true` | **STORE-ONLY** — same; supporting text "After 20 minutes" is hardcoded, no timeout control/key |

### NotificationsPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Do not disturb | TritonSwitch | `notifications.dnd` | same | `false` | **STORE-ONLY** — engine ignores it; worse, `NotificationState.qml` keeps DND in its own local `dndActive` property and the quick-settings toggle mutates that, not the store. The two channels can diverge. |
| On the lock screen | TritonSwitch | `notifications.lockscreenNotifications` | same | `true` | **STORE-ONLY** — lock UI never reads it |

### DisplaysPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Arrangement canvas | static monitor cards | — | — | — | **PLACEBO** — hardcoded x/y, comment admits drag is unimplemented; "Drag to arrange" caption is a lie in v0.1 |
| Scale slider | TritonSlider, `value: 0.7` hardcoded, no handler | — | — | — | **PLACEBO** — wrong control type anyway: board intent is a *stops-slider* (discrete 1.0/1.25/1.5/1.75/2.0), and engine has no scale key |
| Refresh rate chips (60/120/VRR) | hand-rolled Rectangles, **no MouseArea at all** | — | — | — | **PLACEBO** — not even clickable; static decoration |
| Variable refresh rate | TritonSwitch `on: true` hardcoded, no handler | — | — | — | **PLACEBO** |
| Night light | TritonSwitch | `display.nightLight` | `display.nightLight` | `false` | **STORE-ONLY** — engine never reads `display.*`; no gamma/wwan integration. Supporting text (schedule, 3400 K) hardcoded |

### SoundPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Output volume | TritonSlider `value: 0.42` hardcoded, no handler | — | — | — | **PLACEBO** — should be service-backed (pipewire), not store; slider is dead |
| Input volume | TritonSlider `value: 0.7` hardcoded | — | — | — | **PLACEBO** |
| Speakers row | none | — | — | — | PLACEBO (static) |
| Headphones row | none | — | — | — | PLACEBO (static, "Not connected") |

### NetworkPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Wi-Fi radio | TritonSwitch `on: true` hardcoded, no handler | — | — | — | **PLACEBO** — should be service-backed (NetworkService); inert |
| Known network row | none | — | — | — | PLACEBO (static "Your Network · excellent signal") |

### BluetoothPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Bluetooth radio | TritonSwitch `on: true` hardcoded | — | — | — | **PLACEBO** — inert; no BT service exists |
| Devices row | none | — | — | — | PLACEBO (static empty state) |

### AppsPanel.qml

| Row | Control | Reads | Writes | Default | Status |
|---|---|---|---|---|---|
| Web browser / Files / Terminal | none — static text rows | — | — | — | **PLACEBO** ×3 — no pickers, no store keys, no xdg-settings integration |

### UsersPanel.qml — single static row, no controls. PLACEBO by design (read-only v0.1).
### AboutPanel.qml — static identity rows, no controls. PLACEBO by design. Device name is a local property `"neptuno"`, not read from anywhere.

---

## Engine-consumed keys with NO settings UI

| Key | Engine effect | UI gap |
|---|---|---|
| `input.keyboardLayout` | hyprland `kb_layout` | KeyboardPanel shows a static "English (US)" row with no picker |
| `input.repeatRate` | `repeat_rate` int | KeyboardPanel slider exists but is PLACEBO and 0..1-normalized with no int mapping |
| `input.repeatDelay` | `repeat_delay` int ms | same |
| `appearance.accent` | full matugen re-scheme | AppearancePanel emits the signal but nothing writes the store |
| `appearance.mode` | portal color-scheme | same |
| `appearance.wallpaper` | matugen image | reachable only via the Wallpaper picker window (`WallpaperWindow`), not really a gap — but note `wallpaperKind` (written by the picker) is **not** engine-consumed: engine only uses `wallpaper` path. Wallpaper set by *kind* (dynamic/clock kinds) leaves `wallpaper` empty, so matugen falls back to the default wallpaper path — silent wrongness. |

## Store keys written but consumed by nothing anywhere

`shell.revealOnUrgent`, `shell.showWindowTitle`, `shell.batteryWavyRing`, `shell.reduceMotion` (in seed defaults but unread), `power.dimIdle`, `power.suspendIdle`, `display.nightLight`, `input.repeat`, `notifications.dnd`, `notifications.lockscreenNotifications` (both notification keys are bypassed by `NotificationState.dndActive` anyway).

## Visual / structural defects by panel

- **AppearancePanel**: does not use `PanelHeader` (hand-rolled two TritonTexts at different offsets — pixel sizes 40 vs the canonical 32); hardcoded `"#29FFFFFF"`, `"#4DFFFFFF"`, `"#33FFFFFF"`, `"#16356F"`, `"#282A2F"` literals instead of tokens; contrast slider is continuous where board specifies stops; "Standard" subtitle never reflects value; swatch active-state compares `accent === name.toLowerCase()` but "Custom" writes `"wallpaper"` making no swatch ever active for the default state; `transparency`/`tintedSurfaces` have no UI.
- **BarShellPanel**: "Reveal edge" and "Reveal delay" rows render no control at all — read as wired rows but are inert text.
- **WindowsPanel**: "Center focused column" row has no control; panel comment overclaims full store backing.
- **DisplaysPanel**: refresh-rate chips are hand-rolled instead of `TritonChip` (which exists in components and matches the board exactly) — and lack MouseAreas entirely; scale slider should be stops-type; hardcoded monitor geometry mock; `"#16356F"` literal.
- **SoundPanel**: sliders hardcoded 0.42/0.7 — will visibly jump if ever wired; device rows fake.
- **NetworkPanel/BluetoothPanel**: switches hardcoded `on: true` — worst placebo kind, show as always-on regardless of reality.
- **KeyboardPanel**: sliders at fixed 0.5/0.4 with no handlers; layout row static.
- **TritonSlider** (component-level): no `from`/`to`/stepping support at all — only normalized 0..1 — so every consumer needing discrete stops or unit ranges (repeat rate in keys/sec, delay in ms, scale factors) must hand-map. None do. Also lacks `width` defaulting (consumers all hardcode 250/260 — inconsistent).
- **TritonSwitch** has no way to display intermediate/disabled states — fine — but note all panel switches bind `on:` to `get()` which **does not re-evaluate on external store changes** unless the binding stays live; since `get` reads through `store` property it does rebind correctly. No defect, just confirm panels rely on it.
- **PowerPanel**: MouseArea uses `z: -1` trick behind the row — works, but fragile; clicking the trailing radio icon itself may be swallowed differently than the row body.
- **NotificationsPanel**: DND store key is shadowed by `NotificationState.dndActive` — a structural conflict, not just dead wiring.
- **SettingsWindow**: hardcoded `"#1FFFFFFF"` border literal; appearance is the only panel with any signal handlers connected at all, and only for wallpaper browse.

## Summary counts

- WIRED controls: **8** (barMode cards, clockFormat, focusFollowsMouse, naturalScroll, tapToClick, power profile, plus wallpaper read-through)
- STORE-ONLY: **10** (revealOnUrgent, showWindowTitle, batteryWavyRing, reduceMotion, dimIdle, suspendIdle, nightLight, repeat, dnd, lockscreenNotifications)
- PLACEBO: **~15** (all of Sound, Network, Bluetooth, Apps; keyboard sliders+layout; pointer speed; display scale/refresh/VRR/canvas; windows centering; bar reveal rows)
- UNWIRED-SIGNAL: **7** (the entire AppearancePanel core: mode×3-as-one-segment, accent×6, contrast, materials×3-as-one, plus declared-but-control-less transparency/tinted)

The final wiring pass should prioritize: (1) connecting AppearancePanel signals to `SettingsService.set` in `SettingsWindow` or directly in the panel — mode/accent are engine-consumed already, so this is pure win; (2) keyboard repeat rate/delay with unit mapping; (3) killing or implementing the STORE-ONLY keys (reveal/reduce-motion have natural shell consumers waiting); (4) resolving the DND double-source-of-truth; (5) replacing DisplaysPanel hand-rolled chips with TritonChip and wiring scale/refresh through new engine keys or dropping them from v0.1.
