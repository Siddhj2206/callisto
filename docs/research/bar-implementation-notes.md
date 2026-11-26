# Triton bar implementation notes

Implemented the bar in its **revealed** state per `references/BarStates.dc.html`
section 2 ("Floating over the work"). Verified with `qs -p shell/triton` on
quickshell 0.3.2 (host compositor niri): loads with zero errors and zero
warnings, services bind, nothing crashes without Hyprland IPC.

## Files

```
shell/triton/
├── shell.qml                 # ShellRoot + FontLoaders + Variants per screen
├── bar/Bar.qml               # PanelWindow container — owns ALL service bindings
├── bar/Island.qml            # Glass island primitive (`.isl.t-glass`)
├── bar/WaveButton.qml        # 9-lobe wave launcher button (`.wv`)
├── bar/WorkspacePill.qml     # leaf pill (`.ws` / `.ws.on`)
├── bar/Clock.qml             # time + date (`.clk`)
├── bar/StatusGroup.qml       # primary-container status pill (`.stat`)
└── bar/BellButton.qml        # veil notification bell (`.bell`)
```

## Board details implemented

From the BarStates board CSS and markup:

- **Islands**: 56px tall (`Theme.barHeight`), radius 28
  (`Theme.radiusFloating`), glass fill `Theme.glassBg`, floating 8px below
  the top edge (`Theme.space[1]`), 16px from screen edges (`Theme.space[3]`),
  6px horizontal padding / 4px internal gaps per `.isl{padding:0 6px;gap:4px}`.
  PanelWindow is transparent full-width with `exclusiveZone: 0` — "nothing
  reserved", islands cover what is under them.
- **Wave button**: 44px square. `Theme.wavePath` (100x100 viewBox, 9 lobes)
  rendered with `QtQuick.Shapes PathSvg`, scaled 44/100, fill `Theme.primary`,
  "apps" ligature icon 22px centered in `Theme.onprimary` — exactly the board
  markup (`fill:#B0C6FF`, `color:#002D6E`, `font-size:22px`). 8px spacer
  before the first pill per the board's `<span style="width:8px">`.
- **Workspace pills 1–5**: 40px tall, min-width 40, radius 20, Jost SemiBold
  17px. Active = solid `Theme.primary` fill, min-width 56, `onprimary` text.
  Inactive = bare number, `onsurfacevariant`. Click dispatches
  `workspace N` via `Hyprland.dispatch`.
- **Clock**: `HH:mm` in Jost SemiBold 26px + `ddd d MMM` ("Sat 21 Nov") in
  Google Sans Flex 14px medium, `onsurfacevariant`, baseline-aligned, 12px
  gap, board padding 0 16 0 18. Driven by `SystemClock` at Minutes precision
  (no `new Date()`).
- **Status group**: solid `Theme.primaryContainer` pill, 44px tall, radius
  22, padding 0 18, 16px gaps, `onprimarycontainer` content — wifi icon,
  volume icon, battery icon + percentage (6px internal gap).
- **Bell**: 44px veil (`Theme.veil`) circle, radius 22, "notifications"
  ligature icon. The tertiary unread dot from the board markup is implemented
  but hidden — bound to a `hasUnread` property awaiting the notification
  service.
- **Battery icons per board §5**: `bolt` while charging, `battery_alert`
  when low (≤20%), else stepped `battery_N_bar` (N = round(pct/100·6)).

## Service wiring

- **Workspaces**: `Quickshell.Hyprland` singleton, purely event-driven.
  Active workspace via `Hyprland.monitorFor(screen).activeWorkspace`.
  **Degradation**: `monitorFor` returns a stub object even with no Hyprland
  IPC (verified on niri), so liveness is detected via
  `activeWorkspace != null || focusedMonitor != null` — without IPC the pills
  render inert and no dispatch is attempted. No crash either way.
- **Volume**: `Pipewire.defaultAudioSink` with `PwObjectTracker`. Scroll on
  the volume icon adjusts ±5% per notch (clamped 0–1), click toggles mute.
  Icon: `volume_off` muted, `volume_down` < 33%, else `volume_up`.
- **Battery**: `UPower.displayDevice`, shown only when `ready` and
  `isLaptopBattery` — the readout disappears entirely on battery-less
  machines, no placeholders.

## Conventions notes

- Every file starts with `pragma ComponentBehavior: Bound`.
- Leaf components (pill, clock, status group, bell, wave button) take state
  as properties and emit signals; only `Bar.qml` touches services.
- Lowercase `on*` token names throughout (`onprimary` etc.) per
  shell-conventions §3.
- Fonts loaded in `shell.qml` via `Qt.resolvedUrl("fonts/...")`; the
  `fonts/` directory next to `shell.qml` is already synced from
  `design/fonts/`. Family names verified with fc-scan: "Jost SemiBold" picks
  the semibold static weight directly (more reliable than weight matching);
  icons use the "Triton Symbols" family with ligature names.
- **Hardcoded-motion avoidance**: the workspace pill does *not* animate its
  width/color change. The tokens define motion as spring pairs, which QML
  tween animations can't faithfully reproduce — rather than invent hardcoded
  durations (a conventions violation), transitions are deferred until spring
  animation primitives exist in `components/`.
- Off-scale literals are documented where they occur (island 6px padding,
  clock 16/18px padding) as direct board-CSS derivations.

## Deferred

- **Glass blur**: `Theme.glassBlur` is compositor-applied (niri/Hyprland
  blur on the layer surface); QML side carries only the pre-composited
  `glassBg` fill. Needs compositor config wiring.
- Wave launcher button is wired but does nothing — the launcher module
  doesn't exist yet.
- **Wifi icon is static** ("wifi" always): no network service exists yet;
  board §5's `wifi_off` state awaits that service.
- Notification service → bell unread dot and `notifications_off` DND state.
- Hidden/pinned/docked states, reveal edge strip, window-title island growth,
  recording/mic chips, workspace hover previews, background-apps overflow —
  all on the board, all future work.
- Popovers (§6) not started.
