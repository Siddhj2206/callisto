# Surface: Launcher

Board: `Launcher.dc.html`. Replaces: `launcher/Launcher.qml`, `LauncherPanel.qml` (599 lines, 11 font sizes), `ResultRow.qml`.

## Component tree

```
LauncherHost                  SurfaceWindow(layer overlay, keyboard exclusive, Modal scrim scrimSoft)
  Presence role: launcherOpen / surfaceExit   (origin = bar wave button centre on the focused output)
  Panel{material: thick, radiusTier: s (28), width: panel.launcher | panel.launcherCompact}
    SearchHeader
      SearchField{size: launcher, leading: WaveShape(40, tone by mode: primary | primary | tertiary, glyph search|calculate|chevron_right), trailing: ChipGroup}
        ChipGroup: Chip(All, Apps, Files, Windows)  | Chip(Commands, tone tertiary) in command mode
    Divider(hairline)
    ResultsBody (mode switch)
      Mode list:   RowLayout
                     TopHitCard   Card{variant: tonal primaryContainer, w Size.launcher.topHit} -> eyebrow, IconDisc 96 (primary, icon 44 filled), AppText(headlineL, fit) name, AppText(bodyM, med) sub, Row(Button filled "Open", Button veil "New window")
                     ResultsList  ScrollArea -> SectionHeader(groupLabel) + ListRow{density: compact, leading IconDisc 40 (tint), trailing Tag(workspace) | Keycap(Enter) when selected}
      Mode calc:   Column: AppText(bodyS, med) "1,248 / 4" ; AppText(display) "= 312" ; Button(filled, copy) ; Button(veil, Open Calculator)
      Mode command: ListGroup of ListRow(compact, icon, title, subtitle, trailing Keycap on selected)
    Divider(hairline)
    KeyHintBar{tone onSurface: up/down move, Enter open, Tab actions, Alt+Enter reveal, Esc close}
```

## Layout rules (fixes the overflow in the current code)
- Panel width `panel.launcher` pref 900, min 560, max 1000, clamped to screen minus margin; calc/commands 572 / min 440.
- Top-hit card: width `Size.launcher.topHit` pref 310, min 240, max 340; the name
  is `AppText headlineL` with `fit: true` (shrinks to `titleXl` before eliding)
  and two-line wrap off; subtitle elides. Below `panel.launcher.min + topHit`
  the top-hit card moves above the list (column layout).
- Results list height = content up to `Size.launcher.maxResults` rows, then
  scrolls; panel height does not jump while typing (min height of results
  area is the 4-row height so results change in place).
- Footer wraps (`KeyHintBar` is a `Flow`) when narrow.
- Placement: horizontally centred, top at a token fraction (`Size.launcher.topFraction` = 0.12 of output height), on the focused output.

## Motion
`launcherOpen` (spring out of the bar wave: scale from origin + opacity),
`surfaceExit` (fade); row selection `colorShift`; results change in place via
`listReflow`; chip switch `colorShift`. Scrim `scrim`.

## Keyboard
Type to search; Up/Down move selection (wraps), Enter run selected, Tab opens
actions (second list / popover of actions for the row), Alt+Enter reveal in
files, Esc closes (clears first if non-empty? board says "close"), prefix
`>` commands, `=` math, `/` files; Ctrl+1..4 switch filter (proposed).
Super+Space toggles (IPC `launcher toggle`, exists).

## States
list (con), calc (1248 / 4), commands (> dark), empty results (EmptyState
inline), loading (files search, `LoadingWave` in header trailing).

## As built

`LauncherService` was rewritten: substring-only matching and no memory were
audit defect #12. Filters are All, Apps and Windows; there is no file search
yet. Tab shows the selected row's actions in place.

## Salvage
Keep wholesale: `LauncherService` (scoring, `matchedApps`, `topHit`, calc
evaluation, `launch`/`runCommand`, prefix modes), `LauncherState`.
Key handler logic from `LauncherPanel.qml:148` moves to the Host.
Visual code: not salvageable (hard-coded 900 wide card etc.).
