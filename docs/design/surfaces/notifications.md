# Surface: Notifications (toasts + centre)

Board: `Notifications.dc.html` (primary), `Lock` (hidden content), `Containers` (grouped notification), `BarStates` (bell, DND).
Replaces: `notifications/ToastWindow.qml`, `CenterWindow.qml`, `NotificationCard.qml` (295 lines, 12 hex literals), `NotificationCenter.qml` (322).

## Component tree

```
ToastHost                      SurfaceWindow(layer top-right below zoneBar, click-through except cards, no focus)
  Column{spacing 10}  max 4 NotificationCard{context: toast} + OverflowPill(Pill glass, icon stacks, "N more")
    each: Presence role toastEnter / toastExit; stack reflow = listReflow
CenterHost                     SurfaceWindow(layer top-right, full height minus margins, keyboard onDemand)
  Presence role: surfaceEnter / surfaceExit
  Panel{glass, panel.s (28), width panel.notifications 440, pad 18/16}
    Header: AppText(headlineM "Notifications") + Button{size compact (36), tonal, icon dark_mode "DND", toggle}
    ScrollArea
      NotificationGroup x N   (newest first)
        GroupHeader: IconDisc 32 + AppText(titleM name) + AppText(caption count "3 new") + IconButton(chevron expand) + Button(text "Clear")
        stack of NotificationCard{context: center}  (collapsed: 1 card + peek card offset 12 inset @ .5)
        Button(text, "Show 1 more")
    EmptyState (when none)
```

## NotificationCard kinds (T10)
standard (icon disc 48), message (wave avatar 48 + inline reply field + send),
critical (`Material critical`, inverted buttons, sticky, ignores DND),
progress (wavy `ProgressBar` + percent + Pause/Cancel), call (56 wave avatar,
`titleDisplay` name, Decline error / Accept success buttons, flex split),
screenshot (88 x 60 thumb + Open / Show in Files).
Radii: toast `24 24 24 10`; centre item `20 20 20 8`; peek `20 20 20 8`.

## Layout rules
- Toast width pref 400 (min 320, max 440); never wider than screen minus
  margin; body `maxLines 2` (toast) / 3 (centre); title elides; actions wrap
  to a second row below `Size.notification.actionsWrap`.
- Centre width pref 440; height fills; list scrolls; groups collapse
  independently.
- Toast stack top offset = `Space.zoneBar`; if the bar is hidden it is
  `Space.screenMargin`.

## Motion
`toastEnter` (slide + fade), `toastExit` (fade), `listReflow` for stack and
group expand/collapse, `surfaceEnter/Exit` for the centre, hover pause (timer
stops, no animation). Reduce motion: fades only.

## Behaviour
- Timeout `Motion.timing.toast` 6 s; critical and calls sticky; hover pauses;
  max 4 visible, rest collapse into the count pill.
- DND routes toasts to the centre; critical and calls still pop.
- Lock screen shows sender + app only (see `session.md`).
- Keyboard (centre): Up/Down between cards, Enter opens/activates default
  action, Delete dismisses, Left/Right collapse/expand group, `c` clears group,
  Esc closes. IPC `notifications toggle` (Super+N) exists.

## Salvage
Keep wholesale: `NotificationState` (server, groups, DND, overflow, unread,
sweeping timer). Visual code: replace.
