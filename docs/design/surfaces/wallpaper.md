# Surface: Wallpaper picker and desktop wallpaper

Boards: `Wallpaper.dc.html`, `WallpaperStates.dc.html`. Replaces: `wallpaper/WallpaperWindow.qml`, `WallpaperDock.qml` (261), `ColorsCard.qml` (172, 8 hex), `WallpaperThumb.qml`, `WallpaperScene.qml` (117, 16 hex: drawn placeholder scenes), `Desktop.qml` image layer. Dock and cards use `ThemeScope scheme: "follow"` (the board says the shell flips to Light for a light image).

## Component tree

```
WallpaperHost                  SurfaceWindow(layer overlay, keyboard exclusive, transparent: the real desktop is the preview)
  Presence role: surfaceEnter (cards skip the spring under reduce motion)
  PreviewToast (top-left)      Pill{glass, icon visibility, "Previewing on your real desktop. Esc puts the old one back."}
  ColorsCard (top-right)       Panel{glass, panel.m (32), width Size.panel.colors 370, pad 20/22}
    Row: Icon(colors, primary) AppText(titleDisplay "Colors from Orbit") Tag("Live preview")
    Row: Swatch x5 (label micro)
    ToneStrip: Row of 4 CornerShape bars (connected radii 18/6) [primary, secondaryContainer, tertiary, surface]
    Row: Icon(info, primary) AppText(bodyS, med, wrap 3 lines) contrast note
    (light image) preview thumb + "Paper is a light image" + ActionRow: Button(filled "Keep Light") Button(veil-outlined "Stay Dark")
    (loading) blurred thumb + AppText(titleDisplay "Reading colors") + ProgressBar{wavy, w 300} + AppText(bodyS)
  Dock{pattern T12}            Panel{thick, panel.l (36), margins 40/24, pad 22/26/20}
    Header: ChipGroup{round, selectedTone primary}: Pictures Triton Dynamic Colors  ... AppText(caption "Applying to") SegmentedButton(Desktop | + Lock | + Greeter, w fill up to 360)
    CarouselRow of PreviewTile{200 x 120, r lg, selected: ring 3 + check badge (WaveShape 28), scale 1.04} + AddFolderTile
    KeyHintBar{left/right browse, Enter set, Esc revert, R random}
  FolderHeader (folder source): Card: icon folder + AppText(title path) + count
  DynamicSchedule (Dynamic source): 3 cards (Day 06:30-18:00, Dusk 18:00-21:00, Night 21:00-06:30) + time axis
  PerDisplay (Displays option): display tiles + SettingRow switch "Use a different wallpaper per display"

Desktop (per screen, background layer): two Images with `crossfade`; per-display wallpaper path.
```

## Layout rules (fixes hint row overlapping thumbnail labels and cut-off last tile)
- Dock is a column: header, shelf (`implicitHeight` = thumb + caption +
  selection scale margin), hint bar. Never overlapping absolute positions.
- Shelf scrolls horizontally with edge fade and keeps the selection centred;
  never clips the selected tile's ring (shelf padding = ring + scale overshoot).
- Dock width = screen - 2 x `Size.dock.sideMargin` (40, min 16); the header row
  wraps "Applying to" under the chips below `Size.breakpoint.dockWrap`.
- ColorsCard pref 370, hides below `Size.breakpoint.colorsHide` or moves into the
  dock header.

## Motion
`surfaceEnter` (dock y from bottom, cards y from top), `selection` on thumbs,
`crossfade` (effects slow) for wallpaper and palette swap; reduce motion:
wallpaper crossfade 200 ms, no shelf spring.

## Keyboard
Left/Right browse (live preview), Enter set, Esc revert, R random, 1-4 source,
Tab to "Applying to". IPC `wallpaper toggle` (Super+Shift+W) exists.

## Salvage
Keep: `WallpaperState` (preview channel, `show/close(revert)`), the Desktop
preview-vs-store precedence, the engine apply flow. `WallpaperScene` placeholder
painters are not part of the design: replace with real assets. Needs: folder
scan and watch, dynamic-set schedule, per-display store keys, luminance +
palette extraction results from the engine (Q16).
