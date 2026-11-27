# Surface: Clipboard

Boards: `Clipboard.dc.html`, `ClipboardStates.dc.html`. Replaces: `clipboard/ClipboardPanel.qml` (459 lines, 12 font sizes), `ClipboardWindow.qml`.

## Component tree

```
ClipboardHost                 SurfaceWindow(layer overlay, keyboard exclusive)
  Modal{scrim: mid (.35)}
  Presence role: surfaceEnter / surfaceExit
  Panel{thick, panel.l (36), size panel.clipboard (1000 x 780), pad 22}
    RowLayout (two columns)
      ListColumn (pref Size.clipboard.listW 430, min 320)
        SearchField{m, trailing AppText(caption, low "Super+V")}
        ChipGroup (scrolls/wraps): Chip{round} All Text Images Links Code Pinned
        ScrollArea
          SectionHeader(groupLabel "Pinned" / "Today")
          ListRow{density compact, shape soft (r14, selected r28), selectedTone primary, tone veilFaint,
                  leading IconDisc 40 veil (type icon), title bodyM (mono for code), subtitle caption med,
                  trailing: Icon(push_pin) | ProgressRing{wavy 34, countdown monoXs}}
        EmptyState (first run: WaveShape 88, "Nothing copied yet", explainer)
      PreviewColumn (fill)
        PreviewPane: image | text (mono for code) | color swatch (WaveShape + hex monoM) | link | files list
        meta AppText(titleM name) + AppText(caption med "PNG - 1646 x 1029 - 412 KB - from Screenshot, 2 min ago")
        Row: Button(filled, content_paste "Paste") Button(veil, file_copy "Copy as file") IconButton(push_pin, veil) IconButton(delete, veil)
    KeyHintBar{Enter paste, Shift+Enter plain, P pin, Del delete, Tab preview, Esc close}
ClearHistoryDialog            Dialog{icon delete_sweep, "Clear clipboard history?", body "This removes 47 items. Pinned items stay unless you choose to include them.", Cancel, Clear history (danger)}  (solid, with scrim: no glass on glass)
```
Settings rows for clipboard (keep for 1 h/24 h/7 d via `SegmentedButton`, ignore
sensitive and keep images via `SettingRow` switches) belong to the Settings app,
not this surface.

## Layout rules
- Panel size pref 1000 x 780, min 640 x 480, clamped to screen margins; below
  `Size.breakpoint.clipboardSingle` (760) the preview column hides and Tab shows
  it as an overlay page (`drill`).
- List width does not change when previews change (board rule).
- Title elides; meta elides; mono previews scroll both axes.

## Motion
`surfaceEnter/Exit` (reduce: 120 ms fade, panel itself opens in 120 ms), items
`listReflow` (spring in on new capture), selection `colorShift` + `shapeMorph`
(r14 -> r28), countdown ring time-based.

## Keyboard
Type to search; Up/Down move (hover moves preview too), Enter paste and close,
Shift+Enter plain text, P pin/unpin, Del delete, Alt reveal sensitive, Tab
preview focus, 1-9 quick paste (proposed), Esc closes (clears query first
proposed). IPC `clipboard toggle` (Super+V) exists.

## States
list, search ("3 results. Matches text, color names, file names and link
titles"), empty, sensitive (masked dots, countdown, Enter pastes once), clear
dialog, links paste the URL.

## Salvage
Keep: `ClipboardState` (entries, `paste`, `pin`, persistence), `callisto-clipwatch`
(note `docs/research/audit.md` defect 9: sensitive items stored in plaintext - needs the
sensitive-content hint before the masked state can be real). Visual: replace.

## As built

Backend: `cliphist`, filled by `callisto-clipboard.service`
(`wl-paste --watch callisto-clip-store`, which drops anything marked secret).
`bin/callisto-clip` lists and changes the history and keeps pins.
Shell: `services/ClipboardState.qml`, `surfaces/clipboard/`, shared
`patterns/{SearchHeader,ResultRow}`, gallery `gallery/clipboard.qml`.

- Desktop size 760 x 520. Filters sit in the header; the preview never hides.
- No scrim, like the launcher.
- Paste copies, then sends Ctrl+V (Ctrl+Shift+V to known terminals) to the
  window that had focus. Shift+Enter only copies; there is no "paste as plain
  text".
- Pin is Ctrl+P, since letters go to the search field. Ctrl+Shift+Del clears.
- Secrets are never stored, so there is no masked entry with a countdown.
- Not built: "Today" grouping and source app (cliphist records neither), a
  Code filter, "Copy as file", 1-9 quick paste, retention settings.
