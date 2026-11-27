# Surface: Bar

Boards: `BarStates.dc.html` (primary), `Main.dc.html` (placement), `MediaBar.dc.html` (centre island, see `media.md`), `Settings`/`SettingsStates` (Bar & Shell page for the modes).
Replaces: `bar/Bar.qml`, `Island.qml`, `Clock.qml`, `StatusGroup.qml`, `WaveButton.qml`, `BellButton.qml`, `WorkspacePill.qml`, plus the inline edge-sensor `PanelWindow` in `shell.qml`.

## Modes (one tree, three layouts)

| Mode | Board | Window | Material | Reserves space |
|---|---|---|---|---|
| hidden (autohide, "Reveal on edge") | 1 + 2 | `SurfaceWindow` mapped only while revealed; separate 2 px `EdgeSensor` window | glass islands | no |
| floating (revealed) | 2 | layer top, margin `Space.screenMargin` top/sides | `glass` islands | no |
| pinned | 3 | layer top, full width | `mica` strip, square, edge to edge | yes (`exclusive`, height `Size.bar`) |

The first version drew floating islands with `exclusiveZone: 0` in pinned mode
(`docs/research/audit.md` defect 1). `BarStrip` is a real full-width Mica strip
with `SurfaceWindow.exclusive: true`.

## Component tree

```
BarHost (per screen; SurfaceWindow, namespace by mode)
  Presence role: islandReveal / islandHide      (pinned: no animation after first map)
  Bar
    BarLayout (mode-aware)
      LeftGroup                      Island | strip section
        WaveButton                   IconButton{size:slot, shape:wave}: WaveShape(primary) + Icon(apps, onPrimary)
        WorkspaceStrip               Row of parts/WorkspacePill   (Button-like, pillMorph: 40 -> 56 wide, radius full)
        WindowTitle (when enabled)   Divider(vertical, veilStrong) + Icon(app, fill, primary) + AppText(labelL, appName) + AppText(bodyS, emphasis med, docTitle, fade mask at right edge)
      CenterGroup                    MediaPill (media.md), exists only while a player is active
      RightGroup
        IndicatorChips               Pill-like chips: RecordingChip(error), MicChip(tertiary), each with AppText + optional stop IconButton(xs)
        Clock                        AppText(numeralL, tabular) + AppText(bodyS, med) in a Row
        StatusPill                   StatusPill{tone: ok|attention|urgent, items: wifi, volume, battery %}
        BellButton                   IconButton{slot, veil, icon notifications|notifications_off(filled secondaryContainer)} + Badge(dot, ringTone: material)
    Popovers (anchor = triggering item)
      WorkspacePreviewPopover        Popover(w 440, panel.s) -> title row + Row of PreviewTile(150 x 150, r14)
      TrayOverflowPopover            Popover(w 292) -> Grid 3 cols of (IconDisc 56 veil + AppText labelS)
      (media popover in media.md; QS and notification centre are their own surfaces anchored below)
EdgeSensor                           SurfaceWindow(2 px, no material, hover -> BarState.hovering)
```

## Layout rules

- Island height `Size.bar` (56) = slot (44) + 2 x pad (6). Contents centre by
  layout alignment (no per-child offsets).
- Left island grows for the window title (`pillMorph`) and shrinks again. Title
  width cap = `screenW - rightGroupWidth - centreGroupWidth - 4 x screenMargin`;
  clipped with a right-edge fade, never elides mid-word, never pushes the clock.
  If the cap < `Size.h.xl x 2`, the title section hides.
- Centre island is centred on the screen; it hides its title text before it
  would collide with the left or right group.
- Right group never shrinks; status pill drops the battery percentage below
  `Size.breakpoint.barCompact` (proposed 1100 px screen width), indicator chips
  drop labels first.
- Workspaces: `WorkspacePill` min 40, active 56 (Q: 64 in Type demo); count
  from Hyprland; scroll on the strip changes workspace.
- Popovers keep the bar revealed while open; popover position clamps to the
  screen (`Space.screenMargin`).

## Indicator logic (state -> visual)

| State | Visual |
|---|---|
| recording | `errorContainer` chip: filled `fiber_manual_record`, "Recording mm:ss", inner stop button |
| mic in use | `tertiaryContainer` chip with app name (e.g. "Meet") |
| DND on | bell becomes filled `secondaryContainer` with `notifications_off` |
| charging | bolt icon filled `tertiary` before the percent |
| battery low (< 20 %) | whole `StatusPill` -> `errorContainer`, `battery_alert` |
| offline | `StatusPill` -> `tertiaryContainer`, `wifi_off` |
| unread | `Badge dot` on the bell |

"Warm colours mean attention; blue = fine; red = urgent."

## Motion

- Reveal/hide: `islandReveal` / `islandHide` (y translate + opacity). Pinned
  mode maps once and never animates.
- Workspace dot to pill, media pill widen, left island growth, indicator chip
  appear: `pillMorph`.
- Bell/ibtn press: `shapeMorph`. Colour/icon changes: `colorShift`.
- Reduce motion: crossfade only; pill sizes jump.

## Behaviour

- Reveal on 120 ms top-edge dwell (`Motion.timing.barRevealDwell`, configurable
  by the Bar & Shell reveal-delay slider), Super+B (IPC `bar toggle`), or
  window-needs-attention (workspace pill pulses and bar peeks 4 s when
  "Reveal on urgent notification").
- Hide 600 ms after pointer leaves, never while a popover is open or a
  notification is expanded; fullscreen suppresses, 300 ms dwell reveals.
- Keyboard: popovers take focus on open (arrows between items, Esc closes);
  the bar itself is not focusable.
- Material: floating = glass, pinned = mica (adaptive +.08 when wallpaper
  luminance > .6; needs the engine value, Q16).

## Salvage

Keep and move into `BarHost`/services: monitor-aware Hyprland workspace
dispatch and `Hyprland.activeToplevel` title, Pipewire sink tracking
(`PwObjectTracker`), UPower display device and "no battery in a VM -> no
readout" degrade, `SystemClock` precision choice and the 12/24 h format key,
`BarState` (revealed/hovering/flashForUrgent/toggle), the settings keys
`shell.barMode/revealDelay/revealOnUrgent/showWindowTitle/batteryWavyRing/clockFormat`.
Visual code is not salvageable (hard-coded 44/56/26 px, no motion).

New services needed: recording state (from Screenshot record mode / pipewire
screencast), mic-in-use (pipewire source output nodes), workspace window
thumbnails for the preview popover (Hyprland toplevel export), tray overflow
(StatusNotifier via `Quickshell.Services.SystemTray`).

## As built: background apps and privacy chips

- The overflow button shows only while a background app exists. Left click
  activates an app, right click (or the Menu key) shows its menu in the same
  panel, middle click is the secondary action. Esc steps back, then closes.
- An item whose icon the theme lacks gets a generic glyph. One that offers
  neither a themed icon nor a usable image still draws Qt's checkerboard.
- Mic chip: any app recording from a microphone, by name. Video chip: "Camera"
  for a device, otherwise "Screen shared".
- The chips are part of the bar and hide with it; nothing floats on its own.
  With the bar hidden (the default), an open microphone or a recording shows
  only once the bar is revealed.
- Checked in QEMU: a stand-in tray app (menu, submenu, activate), `pw-record`
  for the mic, a stand-in PipeWire video source for the screen chip. Not
  checked: a real app's screen share through the portal, a real camera.
- Recording chip: elapsed time and a stop button.
