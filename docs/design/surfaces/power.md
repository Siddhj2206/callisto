# Surface: Power menu

Boards: `Power.dc.html`, `PowerStates.dc.html`. Replaces: `power/PowerMenu.qml` (284 lines), `PowerWindow.qml`. Runs in `ThemeScope scheme: "dark"`.

## Component tree

```
PowerHost                    SurfaceWindow(layer overlay all outputs, keyboard exclusive)
  Backdrop (QML blur 18, brightness .5, saturate 1.1, tint rgb(0 10 30 / .25))
  Presence role: surfaceEnterSlow / surfaceExitSlow
  Column (centred, top = Size.power.topFraction)
    AppText(display, greeting "Good evening, Sid", fit) ; AppText(bodyL, med, "Up 3 days, 4 hours")
    SegmentedButton{variant: power, size xl, layout row, expandedId: focused}
       items: Lock(primaryContainer) Sleep(secondaryContainer) Log out(secondaryContainer) Restart(tertiaryContainer) Shut down(tertiary, expanded pill with "Press Enter")
    Pill{glass, icon warning(tertiary,fill), "Text Editor has unsaved changes"}  (only when relevant)
    Pill{glass} outcome note ("3 updates install on restart - about 2 min") when it changes the outcome
    KeyHintBar{tone onMedia: left/right move, Enter confirm, 1-5 jump, Esc cancel}
  Footer AppText(monoS, low) "neptuno - triton 0.1"
  CountdownView (after confirm): ProgressRing{wavy, size 132, tertiary, draining 5 s} + AppText(display) number + AppText(titleDisplay "Shutting down") + Button(text "Cancel") + "or press any key"
  UnsavedDialog (replaces countdown): Dialog{icon warning, "2 apps have unsaved changes", ListRow dense per app (icon, name, "- Bar.qml", workspace Tag), actions Cancel(text) Review(tonal) Shut down anyway(tertiary)}
```

## Layout rules
- Group item size: 140 x 140 (compact: 96 x 96 below `Size.breakpoint.powerCompact`);
  expanded pill 300 wide (compact 210). If the 5-item group would exceed screen
  minus margins it wraps to 3 + 2 rows (`SegmentedButton.layout: "wrap"`, the same
  connected radii per row) or switches to compact.
- Greeting scales with the screen (`display` role, `fit`), no overlap with the
  group (column layout, spacing token).

## Motion
`surfaceEnterSlow/Exit`; focus moves the pill (`pillMorph`: width, radius, icon
fill, label fade in); focused colour `colorShift`; countdown ring drains
linearly over 5 s (time-based); any key/click cancels. Reduce motion: fades.

## Keyboard
Opens focused on Lock (safest first). Left/Right (and h/l) move focus, 1-5
jump, Enter confirms, Esc cancels. Lock and Sleep skip the countdown; Log out,
Restart and Shut down start it (and the unsaved-work dialog if needed).
IPC `power toggle` (Super+Shift+E) exists.

## Salvage
`PowerState` (open/toggle/dismiss); the action commands inside `PowerMenu.qml`
(loginctl/systemctl) lift into a `PowerService` (new, tiny). Pending-updates
note and unsaved-window list need Hyprland client data + a `pk-offline-update`
probe (new). Visual code: replace.

## As built

`services/PowerService.qml`, `surfaces/power/{PowerHost,PowerMenu,PowerChoice}`,
`primitives/WavyRing`, `patterns/KeyHint`, gallery `gallery/power.qml`.

- One window per screen. All dim; the focused one shows the menu.
- The backdrop is a translucent blue-black over the compositor's blur, not a
  QML blur of the wallpaper.
- Desktop sizes: 104 px items, 232 px focused pill (board: 140 and 300). The
  group never wraps.
- Any focused action grows, not only Shut down. 1–5 move focus; they do not run.
- Leaving the countdown (key, click, Cancel) returns to the menu.
- The note shows logind "block" inhibitors on shutdown, when Restart or Shut
  down has focus.
- A command that fails sends a critical notification. A blocking inhibitor does
  make restart and shut down fail; there is no "anyway" without a polkit agent.
- No name in the greeting on the live system.
- Not built: the unsaved-changes dialog (Wayland gives no list of unsaved
  documents) and the pending-updates note.
