# Surface: Window switcher

Boards: `WindowSwitcher.dc.html`, `WindowSwitcherStates.dc.html`. Replaces: `windowswitcher/WindowSwitcher.qml` (302 lines; built but not wired in). New `WindowSwitcherState` and IPC.

## Component tree

```
SwitcherHost                 SurfaceWindow(layer overlay, keyboard exclusive), opens after Motion.timing.switcherOpenDelay (120 ms) hold
  Scrim{scrimMid}
  Presence role: surfaceEnter / surfaceExit
  Panel{thick, panel.l (36), width Size.panel.switcher (pref 1212, min 480, max screen - 2 margin), pad 24/24/20}
    Header: Column(AppText(headlineM, fit, focused title) / AppText(bodyS, med, "Work - workspace 2 - Console - 2nd most recent")) + trailing AppText(bodyS, med, "2 of 5")
    Mode cards   : CarouselRow of PreviewTile{size card (220 w), selected -> primaryContainer + 3 px primary ring + lift + scale 1.04, app disc 32, attention Badge(dot, halo), Tag(Floating)}
    Mode compact : Row of IconDisc 32 (selected: circle -> rounded square via shapeMorph) + one PreviewTile above for the selection
    Mode find    : SearchField + ListGroup of ListRow(compact, "title - app", workspace Tag)
    KeyHintBar{tab next, shift+tab back, Q close, F float, Esc cancel}  (same-app mode: ` and shift+`; find: up/down pick, Enter focus, Esc back)
```

## Layout rules
- Cards are 220 wide (token `Size.preview.card`), thumbs 200 x 124 r14 keep aspect with
  cover; the row is a scrolling `CarouselRow` keeping the selection centred
  (board: "selection stays centred"); the panel never exceeds the screen width.
- Mode switch: fewer than 9 windows = cards; 9+ or setting = compact (board);
  below `Size.breakpoint.switcherCompact` also compact.
- Private windows: blurred thumb, `visibility_off` badge, name stays; Alt
  reveals preview.
- Titles in cards elide (max 130), header title uses `fit`.

## Motion
`surfaceEnter/Exit` (panel), `selection` (scale 1.04, ring, shadow; spring
overshoot allowed), compact tile `shapeMorph`, scroll `listReflow`. A quick
tap (< 120 ms) swaps with the last window without ever mapping the surface
(never draws).

## Keyboard
Alt+Tab opens (compositor bind -> IPC `windowswitcher next/prev`), Tab / Shift+Tab
cycle while Alt held, release Alt focuses; Q closes selected window, F floats it,
Esc cancels. Super+` cycles windows of the same app; typing switches to find
mode. Order = focus history across all workspaces (not column position).

## Salvage
Logic in `WindowSwitcher.qml:35` (Keys handling) and the Hyprland client list
-> `WindowSwitcherState` (focus history, `next/prev/commit/cancel`, `close`,
`float`). Visual code: replace. Thumbnails via `ScreencopyView` (shared with
Overview and Bar workspace popover).

## As built

`surfaces/switcher/{SwitcherPanel,SwitcherHost}`, `services/SwitcherState` and
`services/WindowService` (most-recent order, shared with the overview).

- Alt+Tab, Alt+Shift+Tab, Alt+\` and the release of Alt are Hyprland *global
  shortcuts*, so they reach the shell in order. The release bind needs
  `release = true, transparent = true`, and arrives as `released`; without
  either, a quick tap leaves the panel open.
- Cards only: no compact or type-to-find mode (the launcher lists windows), no
  private windows, no scrim.
