# Surface: OSD

Board: `OSD.dc.html`. Replaces: `osd/Osd.qml` (265 lines, 8 font sizes), `OsdWindow.qml`. Also moves the OSD producers out of `shell.qml`.

## Component tree

```
OsdHost                        SurfaceWindow(layer overlay bottom-centre, margin Size.osd.bottom (48), click-through, no focus, all-screens or focused)
  Presence: role osdEnter / osdExit   (one instance; variant swaps = osdMorph)
  OsdPill{variant, icon, value, text, subtext, tone}      pattern T21, Material glass
    IconDisc xl 44 (circle veil)  -> WaveShape(tertiary | errorContainer) when off/muted
    content by variant:
      volume|brightness : Slider{variant: osd, interactive: false, width Size.osd.track} + AppText(numeralL, tabular, min 3 digits)
      muted             : AppText(bodyM "Muted")
      micOff            : AppText(labelL "Microphone off")  (errorContainer wave)
      layout            : AppText(titleDisplay "DE") + AppText(caption "Deutsch")
      workspace         : Row of WaveShape x3 (centre 42 primary + numeralM; sides 30 surfaceContainerHighest)
      track             : WaveShape art 44 + Column(AppText(labelL title) / AppText(caption artist)) + Icon(skip_next, primary)
      battery           : WaveShape(error, battery_alert) + Column("Battery 15%", "About 40 minutes left") + Button{compact, filled, "Saver"}
```

## Layout rules
- Height `Size.osd.h` (64), radius full; width = content width (not the
  board's fixed 330/270/346: Q "OSD width"); min width `Size.osd.minW`; max
  `screen - 2 margin`; text elides.
- Placement: horizontally centred on the active output, 48 px above the edge
  (token `Size.osd.bottom`), above any exclusive zone but below lock.
- Pointer events pass through everywhere (`mask` empty) except the battery
  "Saver" button, which makes the pill interactive (only the pill region).

## Motion
`osdEnter` (spatialFast: y +16 -> 0, scale .96 -> 1), hold `osdHold` 1.2 s
(refreshed by key repeat; battery 6 s; mic-off sticky), `osdExit` (effectsDefault
fade). New OSD while visible: `osdMorph` (width/content cross-fade in place, one
at a time). Slider value changes `sliderRelease`-free (instant set; the
track animates with `colorShift`/width spring `pillMorph`-lite). Reduce motion:
fade only, no morph.

## Behaviour
- Never takes focus; announced to screen readers (`Accessible.role: alert`).
- Volume icon steps off/low/mid/high with level; muted keeps the level.
- Brightness: sun icon fills as it gets brighter.
- Workspace OSD only from keyboard-initiated changes. Track OSD only on
  skip, not every new song. Layout OSD on layout change.
- Shows on the output being used (focused monitor).

## Salvage
Keep: `OsdState` (variant/value/icon/text/...); the Pipewire sink `Connections`
producer from `shell.qml` (with its "skip first observation" fix) moves to
`services/OsdProducers.qml`; mic mute, brightness and layout producers added.
Visual code: replace.

## As built

- Track and low-battery pills exist. Layout and workspace do not.
- The battery warns at 20, 10 and 5 percent, once per discharge; at 5 it stays
  until the charger is in. `Saver` sets the power profile.
- `qs -c triton ipc call osd battery 15` shows it on a machine without a battery.
