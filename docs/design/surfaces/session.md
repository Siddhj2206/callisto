# Surfaces: Lock, Greeter, login states, disk unlock

Boards: `Lock.dc.html`, `Greeter.dc.html`, `LoginStates.dc.html`.
Replaces: `lock/LockScreen.qml` (461 lines, 15 font sizes, 9 radii), `LockWindow.qml`, `greeter/Greeter.qml` (398 lines).
All of these run in `ThemeScope scheme: "dark"` over a processed wallpaper.

## Shared parts
- `LoginCard` (T22) / `PasswordField` (P20) / `WaveAvatar` / `LoadingWave`.
- `SessionBackdrop` (surface-local part): wallpaper `Image` + `MultiEffect` blur + brightness + saturation + tint from `Material.backdrop.{lock,greeter}`. Lock: blur 10, brightness .72, saturate 1.1, tint `rgb(0 10 30 / .2)`. Greeter: blur 12, brightness .62. Blur is done in QML (compositor cannot, Q3); the wallpaper image is the "wallpaperOnLock" key.
- `StatusPill` (wifi, battery, layout code in `monoS`), `MediaPill` compact (lock), `Pill` (calendar event).

## Lock

```
LockHost                         SessionLock (ext-session-lock) per screen; lives for the shell lifetime, never created on demand
  SessionBackdrop
  Presence role: surfaceEnterSlow (lock lifts on unlock: spatialSlow; wallpaper sharpens)
  LockLayout (Item; anchors from tokens)
    TopGroup (centred, top = Size.lock.topFraction)
      AppText(numeralL, weight medium, date "Saturday, 21 November")   board 26 px 500
      AppText(displayHero, clock, fit)                    scales: min(250, 0.243 x screenH)
      Pill{glass, icon event(primary), text "Tomorrow, 10:00 - Design review"}   calendar
    NotificationsColumn (bottom-left, w Size.panel.lockNotif 380)
      Pill-like header: icon visibility_off, "3 notifications - content hidden"
      NotificationCard{context: lock} x N   (sender + app only; 24 r, pad 12/18/12/12)
    LoginCard (centred low)                                 Panel glass (panel.m 32) w 420
      WaveAvatar 96, AppText(titleXl name), AppText(bodyS med "Locked 4 minutes ago")
      PasswordField, fingerprint hint row (Icon + AppText bodyS med)
    BottomRight: PlayerCard{variant: lock-pill (w 360 h 64)} + StatusPill (wifi, battery, layout)
```

Layout rules (fixes the card overlapping the clock):
- Vertical stack zones: clock block anchored top; login card anchored bottom
  with `Layout.maximumHeight` such that `clockBottom + gap <= cardTop`. If the
  screen is too short (< `Size.lock.minHForFull`), the clock scales down (the
  clock role is `fit`) before the card moves; below that the date/calendar pill
  hide.
- Notifications column hides below `Size.breakpoint.lockCompact`; the media
  pill and status pill stack right-aligned.
- Card width pref 420, min 320, max 480; centred horizontally.

States (LoginStates): idle, typing, wrong password (`shake` + clear +
`errorContainer` tint + message "Wrong password. 2 tries left."), fingerprint
(`LoadingWave`-like double wave ring pulse + `fingerprint` 44 icon + "Touch the
sensor" / "Or type your password"), caps lock chip, unlocking (`LoadingWave`
morph + "Unlocking" `numeralL`, then lift on `surfaceEnterSlow` reversed).
Disk unlock (before login): solid dark gradient, no blur, key icon, same field.

Motion: lock appears instantly (security; no animation on lock), unlock plays
`surfaceExitSlow`; field states `colorShift`; `shake`; `loop.fingerprintPulse`,
`loop.loadingMorph`. Reduce motion: no shake, static ring.

Behaviour: typing starts input anywhere; Enter submits; Esc clears field;
Ctrl+U clears; eye reveals 5 s (`passwordReveal`); caps-lock chip is a
passive hint. Fingerprint row shown only when fprintd is present (current code
always shows it: `docs/research/audit.md` defect 8). Battery/status hidden in VMs.

## Lock as built

`surfaces/lock/LockScreen.qml` is the view, `LockHost.qml` the session lock,
`services/LockState.qml` the state and PAM. The greeter reuses
`patterns/SessionBackdrop`, `LoginCard` and `PasswordField`.

Differences from the boards:

- No lift on unlock: the compositor shows nothing behind a lock surface, so
  there is nothing to reveal. The lock appears and leaves at once.
- "Wrong password" without a tries count; PAM does not report one.
- No fingerprint row (not in the first release). Media pill, caps-lock chip and
  the unlocking animation are not built; the card says "Checking…".
- The blur is a Qt effect inside the shell, loaded separately, so a missing
  `qml6-module-qtquick-effects` costs the blur and nothing else.
- Waiting notifications show app names and counts, and hide on narrow screens.

Recovery: `callisto-shell.service` restarts the shell, a marker in
`XDG_RUNTIME_DIR` makes it lock again, and Hyprland's
`allow_session_lock_restore` lets it take the lock back. In between, Hyprland
holds the screen locked.

## Greeter

```
GreeterRoot                      separate greetd Quickshell instance (Q17)
  SessionBackdrop{greeter}
  TopLeft:  Brand (WaveShape logo 56 + orbit ring) + AppText(titleXl "triton")
  TopRight: Column(AppText(displayS clock) / AppText(bodyL med date))
  Centre:   CarouselRow of UserTile (WaveAvatar 96; selected 150 with 1.8 stroke ring, scale 1.12) + "Other..." (dashed ring + add icon)
            AppText(displayM selected name)
            PasswordField{size: field-large (60 pill)}
            Row: Button{glass, icon desktop_windows, "niri", trailing arrow_drop_down} Button{glass, icon keyboard, "US"} -> open Menu (session list / layout list)
  BottomLeft:  StatusPill wifi "Home 5G"
  BottomRight: Row of IconButton{xl, glass}: accessibility_new, restart_alt, power_settings_new (tertiaryContainer @ .8)
  Footer: AppText(monoS, low) "neptuno - triton 0.1 - niri 26.04"
```
Layout: user row centres the selection and scrolls; all anchored groups use
screen margins; password pill pref 460 (min 320). Keyboard: Left/Right change
user, Tab to field/pickers, Enter log in, F-keys not used.

## Greeter as built

`greeter.qml` is a Quickshell entry of its own with
`surfaces/greeter/{GreeterScreen,GreeterHost}` and `services/GreeterState.qml`.
greetd runs `callisto-greeter`, which starts Hyprland with
`configs/greeter/hyprland.lua`; the image carries a copy of the shell in
`/usr/share/callisto/shell`. Any way out other than a login starts tuigreet.
Logs and the last user are in `/var/lib/callisto-greeter`.

Differences from the boards: no accessibility button, session or layout picker
(there is one session and one layout), no "Other…" entry, no footer. Restart
and shut down act at once. The live image shows its password.

## Salvage
Keep: `LockState` (PAM flow, `fieldState`, `errorText`, `lock()/unlock()/submit()`,
`pendingPassword`), the "lock exists for the shell's lifetime" rule in
`LockWindow`. Replace: all visual code. Needs `UserService` (greeter users, avatar
initials, last-used session, accounts via AccountsService/greetd). Dedicated PAM
stack (`docs/research/audit.md` defect 8) is a backend task, not a visual one.
