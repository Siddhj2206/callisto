# Surface: Settings app

Boards: `Settings.dc.html` (window, Appearance), `SettingsStates.dc.html` (Displays, Bar & Shell, Windows, Keyboard, search), `QuickSettings.dc.html` (Network hand-off).
Replaces: all 21 files in `settings/` (`SettingsWindow`, `SettingsSidebar`, `PanelHeader`, `SectionLabel`, `SettingRow`, 14 `*Panel.qml`, `AppearancePanel` 519 lines). `docs/design/settings-architecture.md` (store -> engine) is unchanged.

## Window tree

```
SettingsApp                   FloatingWindow (class callisto-settings so the float rule matches: docs/audit.md defect 2), pref 1100 x 760, min 720 x 520, fills when tiled
  WindowFrame                 radius 28, windowOutline, floatingLarge (Q13)
    RowLayout
      SidebarNav (mica, w 280)  SearchField{m} + groups:
          Connect: Network, Bluetooth
          Devices: Displays, Sound, Keyboard, Mouse & touchpad, Power
          Triton: Appearance, Bar & Shell, Windows, Notifications
          System: Apps, Users, About
      ContentStack (solid surface)   role: drill / crossfade
          SettingsPage{title, subtitle} | SearchResults
    ChecklistToast (bottom-right, glass): "Applying Planet - matugen, 6 of 7 targets" rows check_circle | LoadingWave per target (Triton shell, GTK 4, GTK 3, Terminal, Qt, Editor) with monoS file names
```
Narrow (< 860): sidebar becomes a full-width list; each page slides in over it
(`drill`) with a back `IconButton`.

## Layout rules (fixes the fixed 1100 x 760 item)
- Content column: horizontal padding 32 (16 narrow), `maximumWidth`
  `Size.settings.contentMax` (proposed 760) centred when the window is wide;
  `fill` otherwise. Page scrolls (`ScrollArea` with bottom fade 60).
- Rows: control column `maximumWidth` 320; below narrow, controls wrap under the
  title. Card grids (`Materials`, `Bar mode`) use a `GridLayout` with
  `columns = clamp(width / Size.settings.cardMin, 1, 3)`.
- Toast has min width 260 (the board's 230 wraps "GTK 4 - libadwaita") and clamps
  to the window.

## Pages (composition)

| Page | Tree |
|---|---|
| Appearance | HeroPreview (Card r24, h `Size.settings.hero` 200: wallpaper + mock panel) ; SegmentedButton(Dark / Light / Auto at sunset, icons) ; Section "Accent": ListRow containing Row of Swatch x5 + Custom (ring+add), selected check ; SettingRow Contrast + Slider{stops 3} ; Section "Materials": Row of 3 OptionCard (preview thumb, title, caption: Solid / Mica / Glass; selected secondaryContainer) ; SettingRow switches "Fall back to Solid on battery saver", "Glass on floating windows" ; Section "Shape and motion": Expressiveness Slider{stops 3: Calm/Expressive/Playful}, Reduce motion Switch |
| Network | ListGroup: Wi-Fi (Switch), Ethernet, VPN (chevron); network list; hand-off selects the passed network |
| Bluetooth* | adapter Switch + device ListGroup (connected tag) |
| Displays | MonitorArranger (Card with draggable DisplayTile per output: icon, name, monoS resolution; selected primaryContainer) ; Section "eDP-1 - Built-in display": Scale Slider{stops}, Refresh rate ChipGroup (60 Hz, 120 Hz, VRR), VRR Switch, Night light Switch with schedule subtitle |
| Sound* | output/input device ListGroup (active mark), volume Sliders, per-app volumes |
| Keyboard | SearchField "Search shortcuts" ; Section "Shell" / "Windows": SettingRow with Keycap{raised} sequence; conflict subtitle ("Also used by Open launcher") in `error` tone |
| Mouse & touchpad* | switches and sliders (natural scroll, tap to click, sensitivity) |
| Power* | profile ListGroup (radio), idle/suspend switches |
| Bar & Shell | Row of 3 OptionCard (Hidden "Only on Super", Reveal on edge "Autohide, default", Pinned "Takes 32 px" - Q5) ; Section "Autohide": Reveal edge SegmentedButton(Top/Bottom), Reveal delay Slider + monoS value, Reveal on urgent notification Switch, Show window title Switch ; Section "Indicators": Battery as wavy ring Switch, Seconds in clock Switch |
| Windows | LayoutPreview (Card with mini tiled+floating diagram) ; Section "Layout": Gap Slider (0 px), Corner radius (0 px), Floating radius (28 px), Preset column widths ChipGroup (1/3, 1/2, 2/3, add) ; Section "Focus": Focus follows mouse Switch, Center focused column SegmentedButton/ChipGroup (Never / Overflow / Always) |
| Notifications* | DND, lock-screen content switches, per-app list |
| Apps* | default apps + installed flatpaks list |
| Users* | account rows with WaveAvatar |
| About* | Card with version, hardware rows (monoS) |
| Search | SearchResults: "Results for 'blur'", "4 matches. Press Enter to open the first." ListGroup of ListRow(icon = page icon, title with highlighted match, subtitle "Appearance - Materials", trailing chevron) |

`*` = no board (Q14); compose from `SettingRow`/`ListGroup` using the content the
current panels already wire.

Surface-local parts: `HeroPreview`, `MonitorArranger`, `LayoutPreview`,
`AccentPicker` (Swatch row), `OptionCard` (Card + PreviewTile + check). If
`OptionCard` is used on more than Appearance and Bar & Shell, promote it.

## Behaviour
- Everything applies live (no Apply button); the checklist toast reports targets.
- Typing anywhere starts a search ("Search first"); Esc clears search / goes back;
  Ctrl+F focuses search; Up/Down in sidebar, Tab to content, Super+Shift+V tiles
  the window (caption on board).
- IPC `settings toggle` (Super+,) exists; add `settings open <page>` for the QS
  hand-off and launcher commands.

## Motion
`surfaceEnter` for the window content, page change `crossfade` (wide) or `drill`
(narrow), selection pill in the sidebar `shapeMorph` + `colorShift`, switch/slider
per primitive, checklist rows `colorShift`, toast `toastEnter/Exit`, hero preview
`crossfade` on theme/accent change.

## Salvage
Keep: `SettingsService` (with the atomic-write and dropped-apply defects, audit
3-5, fixed separately), `SettingsAppState`, the store keys:
`appearance.{accent,mode,contrast,wallpaper,wallpaperKind,wallpaperOnLock}`,
`shell.{barMode,revealDelay,revealOnUrgent,showWindowTitle,batteryWavyRing,clockFormat,reduceMotion}`,
`display.{scale,refreshRate,vrr,nightLight}`, `input.{keyboardLayout,naturalScroll,repeat,repeatDelay,repeatRate,sensitivity,tapToClick}`,
`power.{profile,dimIdle,suspendIdle}`, `notifications.{dnd,lockscreenNotifications}`,
`windows.focusFollowsMouse`. Each panel's service calls (Network, Bluetooth,
Pipewire, display) are the salvageable half; layouts are not. Note
`docs/audit.md` defect 11: the accent seeds in `AppearancePanel.qml` contradict
the boards (Hull pale, Rock orange): take seeds from the board
(`#2458C8 #D8DEE8 #C0552A #1B2A4A #4FA3A5`).
