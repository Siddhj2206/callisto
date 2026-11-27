# Surface: Overview

Board: `Overview.dc.html`. Replaces: `overview/Overview.qml` (321 lines, 6 hex), `OverviewWindow.qml`. Runs in `ThemeScope scheme: "dark"`.

## Component tree

```
OverviewHost                  SurfaceWindow(layer overlay, keyboard exclusive, all outputs; per-output content)
  Backdrop (QML blur 14, brightness .5, saturate 1.1)
  Presence role: surfaceEnterSlow (zoom/scale 1.04 -> 1 + opacity) / surfaceExitSlow
  SearchPill  Panel{glass pill, h Size.h.xl, w Size.overview.search} : WaveShape 36 + AppText(bodyL med "Type to launch or jump to a window")
  RibbonsScroller (vertical, snaps to workspace, spatialSlow)
    OverviewRibbon x workspaces
      Label column: WaveShape badge 56 (primary if active else surfaceContainerHighest) + AppText(numeralL) + AppText(titleDisplay name) + AppText(caption "4 windows")
      Strip: Row of PreviewTile{source: window thumbnail (live), radius md, title via Pill glass at the corner (icon + app name), focused: ring + halo (Elevation.focusedWindow)}
      Plate: active ribbon `veil` @ .08, radius 32 on the left, bleeds off the right edge
  KeyHintBar{tone onMedia: scroll workspaces, drag move a window, Super+Tab cycle, Esc back}  in a bottom pill (h Size.h.xl? 52)
```

## Layout rules
- Thumbnails keep window aspect ratio; ribbon height = `Size.overview.ribbonH`
  fraction of output height (board 515 of 1029, i.e. ~0.5); the focused ribbon is
  centred, neighbours peek above/below; width overflow scrolls horizontally with
  edge fade.
- Window name pill truncates (`maxWidth` = thumb width - margin).
- With 0 windows a workspace shows an `EmptyState` tile; with many windows, tiles
  shrink down to `Size.overview.minThumbW` before scrolling.

## Motion
`surfaceEnterSlow/Exit` for the whole view; workspace change scroll uses
`spatialSlow` on y; focus ring appears with `selection`; drag lifts the tile
(`lift` shadow, `dragged` state layer). Reduce motion: crossfade.

## Behaviour / keyboard
Super+Tab toggle (IPC `overview toggle`), Left/Right/Up/Down move focus between
windows/workspaces, Enter focuses, scroll wheel changes workspace, drag to move a
window between workspaces, typing opens the search pill (launch or jump),
Esc/click empty area closes.

## Salvage
Keep: `OverviewService` (workspaces/ribbons from Hyprland, `activateWindow`),
`OverviewState`. Window thumbnails need `ScreencopyView` (Quickshell
`Quickshell.Wayland`) - not used today. Visual code: replace.
