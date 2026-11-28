# Surface: Quick Settings

Boards: `QuickSettings.dc.html` (primary: main page, Wi-Fi drill-in, hand-off), `Main.dc.html` (header battery line, 6 tiles, media card, 52 px pill sliders).
Replaces: `quicksettings/QuickSettingsPanel.qml` (429 lines), `QsWindow.qml`.

## Component tree

```
QuickSettingsHost             SurfaceWindow(layer top-right, margin zoneBar, keyboard onDemand, dismissOnOutside)
  Presence role: surfaceEnter / surfaceExit
  Panel{material: glass, radiusTier: m (32; Q4), width: panel.qs}
    PageStack{page: main | wifi | bluetooth | sound}      role: drill
      MainPage
        Header: AppText(titleDisplay "Quick settings") [+ battery line AppText(bodyM, med) "82% - 6 h 10 min left"] , Row of IconButton{veil}: settings, (lock, power: Main variant)
        TileGrid{columns 2}
          Tile x4..6: Wi-Fi, Bluetooth, Sound, Night light, (Do not disturb, Power saver, Dark style in Main)
        Column of SliderRow: Icon + Slider{variant standard|pill, stops optional}  (brightness, volume)
        (optional) PlayerCard{variant: qs}                 when a player is active (Main)
        Footer Row: Button{variant: filled-container "All settings", fullWidth} + IconButton{l, veil, power_settings_new}
      NetworkPage (Wi-Fi drill-in)
        Header: IconButton(back, veil) + AppText(titleDisplay) + Switch
        ListGroup{corner: connected 22/6}: ListRow{h 60, leading Icon(wifi strength; filled primary if connected), title labelL, subtitle caption, trailing Icon(check_circle fill primary | lock)}
        Footer: Button{variant: tonal-container, icon open_in_new, "All network settings"}
      BluetoothPage / SoundPage: same layout (device rows, output list)
```

## Layout rules
- Width pref 400 (min 320, max 440), anchored under the right island, right
  margin `Space.screenMargin`; height = content (max = screen height minus
  `zoneBar` and margin; the page body scrolls, header and footer stay).
- Tiles: 2 columns while width >= `Size.qs.twoCol` (280), else 1 column; text
  elides (label 1 line, subtitle 1 line); tile height `Size.h.tile`.
- Sliders fill the width; leading icon fixed.
- Panel never grows into a sidebar (board rule). Pages drill in place; deeper
  settings open the Settings window on the right page.

## Motion
`surfaceEnter/Exit` for the panel; `drill` for page slide (x +/- width); tile
toggle = `shapeMorph` (round to square, Q1) + `colorShift`; slider `sliderRelease`.

## Keyboard
Arrow keys move between tiles (grid navigation), Enter/Space toggles, Right or
Enter on a drillable tile drills in, Left/Backspace/Esc back (Esc on main page
closes); Tab cycles regions (tiles, sliders, footer). IPC `quicksettings toggle`
(Super+A) exists.

## States
tile on/off; drillable; Wi-Fi disabled (list replaced by EmptyState "Wi-Fi is
off"), scanning (`LoadingWave` in header), connecting row (`ProgressRing`
small), no adapter (tile hidden, degrade per conventions rule 10), no
audio sink (slider hidden), no backlight (slider hidden).

## Salvage
- Keep: `NetworkService`, `BluetoothService`, `QuickSettingsState`, the tile
  list model shape (`{glyph,label,sublabel,on,drillable}` becomes the
  `TileGrid` model), `onGearClicked/onAllSettings/onPowerClicked` handoff.
- Extract from `QsWindow.qml`: Pipewire sink volume and `brightnessctl` Process
  into `AudioService` / `BrightnessService`.
- Visual code: replace.
