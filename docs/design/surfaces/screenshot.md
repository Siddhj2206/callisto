# Surface: Screenshot, capture states, markup

Boards: `Screenshot.dc.html`, `ScreenshotStates.dc.html`. Replaces: `screenshot/ScreenshotUI.qml` (332 lines; built but not wired in). New `ScreenshotState` + IPC `screenshot open|screen|record`. Chrome uses `ThemeScope scheme: "dark"`.

## Component tree

```
CaptureHost                    one SurfaceWindow per output (layer overlay, keyboard exclusive)
  FrozenImage                   (screencopy at open, so the UI is never in the capture)
  Dim{scrimCapture .5; screen mode .16}
  Presence role: surfaceEnter / surfaceExit
  mode region : SelectionFrame (2 px primary, thirds lines veilStrong, corner + edge handles) + Pill{glass mono, icon crop "700 x 480"}
  mode window : window tint primary @ .16 + 2 px outline + Pill{glass, icon + app name}
  mode screen : 4 px inset primary border + Pill{mono "eDP-1 - 2880 x 1800"}
  HintPill (top centre)        KeyHintBar in glass pill h 48 r24
  Toolbar (bottom centre)      pattern T23
    SegmentedButton{l, veil}: Region / Window / Screen
    Divider(vertical 36)
    IconButton{l, veil} pointer, Button{l, veil, icon timer, "Off"}, IconButton{l, veil, videocam}
    CaptureButton               WaveShape 64 primary + Icon(photo_camera 28); record mode: tone error + fiber_manual_record
  record mode: Row of Pill{glass, mic|speaker|ads_click} toggles
  Caption (below toolbar): AppText(bodyS, shadowed "Saves to Pictures/Screenshots and copies to the clipboard")
Countdown                      WaveShape 200 error + AppText(displayXl number) + Keycap(Esc)
AfterCaptureCard               SurfaceWindow bottom-left: Panel{glass, panel.s (28), w 340} -> thumbnail (h 170 r18), AppText(titleM name) + AppText(monoS dims), Tag/Chip "Copied", Row: Button(filled "Edit", fill) IconButton(veil folder_open) IconButton(veil delete), ProgressBar(flat 4 px, 5 s)
MarkupEditor                   WindowFrame/FloatingWindow (glass, w 700): tool row (h 52) IconButton{44, r14} x8 (pan_tool_alt, edit, ink_highlighter, arrow_right_alt, rectangle, title, blur_on, crop; selected secondaryContainer), Divider, Swatch squares 28 r14 x4 (palette colours), IconButton(veil undo/redo), canvas, actions Discard(text) Copy(tonal) Save(filled); text labels are rust (tertiaryContainer) pills
```

## Layout rules
- Toolbar width = content; below `Size.breakpoint.toolbarCompact` segments drop
  labels (icons only). Hint pill hides keys on narrow screens (keeps Esc).
- Size chip follows the selection and flips inside the screen near edges.
- After-capture card clamps to the screen margin; thumbnail keeps ratio.

## Motion
`surfaceEnter/Exit` for chrome, `selection` for window hover, mode switch
`shapeMorph`/`colorShift`, card `toastEnter/Exit` (slides up bottom left), 5 s
progress time-based (hover pauses), countdown number swap `colorShift`+scale
(`spatialFast`). Reduce motion: fades.

## Keyboard / behaviour
Print opens (remembers mode), Shift+Print = whole screen now. Drag to select,
Space window mode, Enter capture, Shift = copy only, Alt includes private
windows, Tab next monitor, arrows nudge selection, Esc cancel. Chrome, bar and
notifications never appear in the image. Recording shows the bar chip.

## Salvage
Selection geometry code in `ScreenshotUI.qml` may be reused. Needs `grim`/`slurp`
or `ScreencopyView` capture service and `wf-recorder` for video (new
`ScreenshotService`). Visual code: replace.

## As built

`surfaces/screenshot/{ScreenshotHost,CaptureScreen,Countdown,ResultCard}`,
`services/ScreenshotState` and `scripts/engine/callisto-shot`.

- `callisto-shot` freezes each output with `grim` before the overlay maps, crops
  from that frozen image, writes to Pictures/Screenshots and copies with
  `wl-copy`. The frozen images are deleted when the capture ends.
- Region, window and screen modes (Space or 1/2/3), delay, pointer toggle,
  arrows nudge, Shift+Enter copies without saving. Print opens, Shift+Print
  captures the screen, Super+Shift+S also opens. IPC `screenshot open|screen`.
- The after-capture card offers view, show folder and delete, and holds for 5 s
  (hover pauses it). The bar and toasts stay out of the way while capturing.
- Video (`V` or the camera button): countdown of at least 3 s, then
  `wf-recorder` in its own user unit (`callisto-record`), which survives a shell
  restart. Microphone or speaker sound, one at a time. Stop from the bar chip,
  Print, or IPC `screenshot stop`. Files go to Videos/Screencasts. Checked in
  QEMU (software encoding).
- Not built: both sound sources at once, click highlighting, a video thumbnail
  on the result card, the markup editor, selection resize handles,
  private-window handling and Tab between monitors.

In the QEMU VM, hover does not follow the pointer until a click, in the shell and
in `foot` alike: the Wayland log shows `wl_pointer.motion` with no `frame` after
it. Check hover on real hardware.
