# Triton component system

Status: written 2026-11-27 as a proposal; building started the same day.
Section 0a says what was actually built and wins over the rest.
Per-surface trees live in `docs/design/surfaces/*.md` (index in section 6).

Goal: rebuild the Callisto desktop shell the way a website is built on
shadcn/ui. Everything is a component. Components are built from a small set of
primitives. Tokens are centralised and generated. Motion is centralised. A
surface file contains composition only: no raw sizes, colors, radii, font
sizes, or animation durations.

Sources read for this document: all 30 boards in `references/*.dc.html` (CSS,
markup, caption text), `references/triton/{tokens.json,tokens.css,components.css,README.md}`,
`references/canvas.json`, the rendered boards in `/tmp/boardout/*.png`,
`docs/shell-conventions.md`, `docs/research/design-board-map.md`,
`docs/audit.md`, `docs/design/settings-architecture.md`, `shell/triton/**`,
`scripts/generate-theme.py`, `configs/hypr/hyprland.lua`.

`docs/research/design-board-map.md` is mostly right. It is thin or silent on
Settings, SettingsStates, Wallpaper, WallpaperStates, Controls, Containers,
ComponentIndex, Materials, Type and Color; section 2 below covers those from
the boards. Where this document disagrees with the map, the board wins.

---

## 0a. As built

Components are added when a surface needs them. The catalog in section 4 is a
menu, not a work list.

- Layout: `shell/triton/{tokens,foundations,primitives,patterns,surfaces}`,
  imported as `qs.<folder>`.
- Tokens: `Colors` (with the `Scheme` type), `Metrics`, `Typography`, `Motion`,
  generated from `design/tokens.json` (`ui` section). `Metrics` also holds
  radii and the wave path. Shadows are not built yet.
- Names changed to avoid clashes: `Palette` -> `Scheme`, `Type` ->
  `Typography`, `Scope` -> `Theming`. Color roles for content are lowercase
  (`onsurface`), as `Theme` already did.
- Motion: spatial values go through a `Spring` object (`width: s.value`), not
  a `Behavior` subtype, which QML cannot express. Opacity and color use
  `Fade` / `ColorFade`.
- A surface is a pure view (`Bar`, `OsdPill`) plus a `...Host` that owns the
  window and services. The gallery renders the views with sample data.
- Overlays use `patterns/OverlayWindow`: a transparent window over the whole
  focused screen that reports clicks outside and stays up through the exit.
  Drop-down panels use `patterns/Popover` on top of it, which adds Esc.
- Icons use native text rendering; Qt's distance fields distort the filled font.
- Hyprland dispatch from the shell uses the Lua form,
  `hl.dsp.focus({ workspace = 2 })`.
- Legacy surfaces still use `Theme` and `components/` until rebuilt.

## 0. Findings that shape the design

1. **The compositor is Hyprland, the boards were written for niri.** Boards and
   `tokens.json` talk about `background-effect { blur true; xray ... }`.
   `configs/hypr/hyprland.lua:117-121` gives every `quickshell` layer one blur
   rule (`blur = true, ignore_alpha = 0.05`) and `no_anim = true`. So:
   - The shell owns all motion (good: matches the goal).
   - Per-material blur radius, saturation and brightness from the boards cannot
     be reproduced by layer rules. Only the fill alpha and the layer namespace
     are ours to choose (open question Q3).
2. **`scripts/generate-theme.py` mis-generates the veil.** Lines 131-136 use
   `state_layer.hover` (0.08) and `state_layer.focus` (0.10) for `Theme.veil`
   and `Theme.veilBright`. The token (`material.veil`) says 0.10 and 0.16. The
   generator also ignores `material.light.*`, `material.mica_adaptive`,
   `elevation`, `type.scale`, `size`, and `shape.list_*`/`connected_*`.
3. **`Theme.applyUserTokens` only recolours.** In light mode it updates the 28
   colour roles and `glassBg` (with the dark alpha 0xB2, not 0.82) but not
   `micaBg`, `thickGlassBg`, `veil*`, or anything else. Light mode is broken
   at the token layer before any surface code is involved.
4. **Light is never drawn on any board.** `Color.dc.html` shows light swatches;
   `Materials`/`tokens.json` give light fills; no surface is shown in light.
   Light state-layer ink, highlight, shadow and full-screen scrim behaviour are
   unspecified (Q2).
5. **There is no MediaBar in the shell.** `grep Mpris shell/triton` is empty.
   `MediaBar.dc.html` is a whole new surface plus a new service.
6. **Screenshot, window switcher and greeter exist but are not wired**
   (`docs/audit.md` defect 10). They are rebuilt like the others and wired in
   at the same time.
7. **The bar's "pinned" mode must be a full-width Mica strip with an exclusive
   zone** (`BarStates` board 3, `docs/audit.md` defect 1). Three bar modes
   (hidden / floating / pinned) are three layouts of one component tree, not
   three components.
8. **Several boards disagree with each other** on chip shape, panel radius,
   QS tile on-state, scrim values, hover tint, section-header style, and more.
   Section 9 lists them. The component API makes each one a single variant or
   token so the answer can be changed in one place.

---

## 1. Rules (replace `docs/shell-conventions.md` rules 2 and 9 when adopted)

R1. **Numeric literals are allowed only in `tokens/` (generated) and in
`foundations/` implementation math.** Primitives, patterns and surfaces may use
`0`, `1`, `-1`, `0.5` (centring), `Layout.fillWidth`, and token references.
A lint script (`scripts/lint-literals.py`) fails CI on any other number or any
`#hex`/`Qt.rgba`/`font.pixelSize`/`duration:` outside `tokens/` and
`foundations/`.

R2. **Three token tiers.**
- Reference tokens: the raw scales (`Space`, `Shape`, `Type` sizes, springs).
- System tokens: meaning (`Palette.surfaceContainerHigh`, `Motion.surfaceEnter`,
  `Type.bodyM`).
- Component tokens: per-component metrics tables inside the component
  (`Button` knows its `s/m/l/xl` heights, radius, padding, font role, icon
  size). Surfaces never see component tokens; they pick `size: "l"`.

R3. **Colour is requested by role, never by value, and always through a
palette.** A component reads colours from the nearest `ThemeScope` palette, not
from `Theme` directly (section 4.1). This is what lets lock, greeter, power,
overview and capture force a dark palette over a dimmed wallpaper while the
rest of the shell follows light/dark.

R4. **Veils are state layers of the palette ink**, never white-alpha
constants. `ink` is `#FFFFFF`-ish in dark and `rgb(25 28 32)` in light.

R5. **Every surface that appears or disappears goes through `Presence`.** The
window's `visible` binds to `presence.mapped`, not to the state singleton's
`open`. Exit is animated, then the layer surface is unmapped.

R6. **Layout is fluid inside tokenised bounds.** A panel states
`preferred / min / max` widths (and a screen margin); it never states a
width as a bare pixel count. Text elides or wraps with a stated line cap.
Rows grow with content (`implicitHeight`), never with a magic `height:`.
Only the hero display roles scale with the screen.

R7. **Leaf components receive state as properties; containers own services.**
(unchanged from conventions rule 9; the library makes it enforceable because
every primitive has no service imports).

R8. **One component per concept.** Accent swatches, chips, keycaps, list
rows, cards, icon discs, section headers, key-hint bars, empty states each
exist once. A surface that needs a variation adds a `variant`, not a copy.

R9. **Reduce motion is a property of `Motion`, not of each component.** No
component reads `Theme.reduceMotion`.

---

## 2. Board inventory (task 1)

Columns: what the board specifies as visual elements, then states. `*` marks
something not in `docs/research/design-board-map.md`.

### 2.1 Foundations boards

| Board | Elements | States / rules |
|---|---|---|
| Color* | Primary/secondary/tertiary/error pairs with contrast ratios; 5 surface tiers; on-surface, on-variant, outline, outline-variant; dark and light swatches; matugen provenance (`tonal-spot`, seed ~#2458C8); signal LEDs | roles: primary = action/focus (one filled primary per view), tertiary = warmth never action, containers = state; hover/focus/press/drag 8/10/10/16 %; disabled 38/12 %; signals are 8 px dots only |
| Type* | Scale table (Display 64 ... Mono 14/24), three font cards, shape scale 0/8/12/16/20/28/full + wave, shape-morph demos (toggle circle to square, workspace dot to pill, press tightens), six spring curves with step responses | emphasis steps weight 400 to 600, never italic; numerals in Jost; targets 40 px minimum; springs fast/default/slow spatial, fast/default/slow effects |
| Materials* | Solid, Mica, Glass specimens with spec cards (Fill/Use/Never/Edges/Fallback/Rules); `Bar.qml` code sample; menu rows with `.mi.hov` | Mica falls back to solid on battery saver or after long focus loss; Glass: no glass on glass; text under 4.5:1 goes solid |
| Controls* | Buttons (filled/tonal/outlined/text/elevated) at 32/40/48/56; icon buttons (standard/filled/tonal/outlined); connected group; split button; view toggle; FAB S/M/L/extended; chips (4 kinds); switch/checkbox/radio; 4 sliders (M44 with icon, S28, range 16, centred 28); progress (wavy, flat, waiting, circular, loading morph); text fields (underline, focused ring, error, pill search); tabs; nav rail; badges (dot, count); wave avatar; tooltip | button states: rest, hover (+10 % of on-colour), focus ring (2 px on-surface, offset 2), press (radius 12), disabled (38 %); toggle off = round + neutral, on = squared + primary |
| Containers* | Menu + submenu (Glass r28, 48 px pill rows, key hints), toast with Undo, dialog (thick glass, scrim 45 %), lists (segmented rows, selected row, check, expand), cards (filled, tonal, outlined), grouped notification, scrollbar (4 px rest, 10 px hover), divider | destructive = error container never primary |
| ComponentIndex* | The component table: Button, Icon button, Connected group, Switch, Slider, Wavy progress, Loading wave, Chip, Floating label, Search field, List and row, Nav item, Card, Menu, Dialog, Toast, Tooltip/badge/tag, Key cap, Scrollbar, Wave, Island, Window frame, Material surface, Preview card, Player card, OSD, Section label | Defines the component names this document keeps |
| Adwaita | libadwaita re-skin | out of scope for the shell (GTK theming via the engine) |
| Main | Composed desktop: bar, Files, Console, Calculator, QS panel | Reference for placement only |

### 2.2 Shell surface boards

| Board | Elements | States |
|---|---|---|
| BarStates | hidden edge strip; floating islands (left: wave button, workspaces, optional window title; right: clock, status pill, bell); pinned Mica strip; indicator chips (recording, mic, DND, charging, low battery, offline); workspace preview popover; tray overflow popover | reveal on 120 ms dwell / Super+B / urgent; hide 600 ms after leave; never hidden while popover or expanded notification; fullscreen suppresses (300 ms dwell); floating = Glass, pinned = Mica |
| MediaBar | centre island (wave art, title/artist, 3-bar level meter, transport), media popover (112 px wave art, wavy progress, transport, volume), player picker list | nothing playing = no pill; playing; hover widens with prev/next; paused dims, no meter, fades out after 2 min; popover; several players |
| Launcher | search row (wave+icon badge, query, filter chips), top-hit card, result rows, group labels, workspace tag, key-hint footer, calc result, command mode | typing, calc (`=`), commands (`>` tertiary), files (`/`); selected row; opens from the bar wave |
| OSD | glass pill (icon disc, 16 px track, value, optional extras) | volume, muted (disc becomes rust wave), brightness, mic off (error), keyboard layout, workspace waves, track change, battery low (action, 6 s); one at a time, morphs in place |
| Notifications | toast stack, notification centre (groups, DND), card types: standard, message (reply), critical, progress, call, screenshot; "N more" pill | hover pauses timer; 6 s timeout; DND routes to centre; critical/calls ignore DND; lock shows sender+app only |
| QuickSettings | 400 px glass panel: header, 2-col tile grid, brightness and volume sliders (stops), "All settings" + power; Wi-Fi drill-in page (back, master switch, network list, footer) | tile off/on (shape morph in Main), drill and back; hand-off to floating Settings |
| Lock | blurred wallpaper, huge clock, date, calendar pill, notification list (content hidden), login card (wave avatar, name, field, fingerprint hint), media pill, status pill | see LoginStates |
| Greeter | brand, clock, user carousel (96 px waves, 150 px selected, "Other..."), password pill, session and layout pickers, wifi pill, accessibility/restart/power circles, footer | selected user; picker menus |
| LoginStates* | the single shared field and wave | idle, typing (primary ring, go fills, eye reveals 5 s), wrong password (shake once, clear, error tint + message), fingerprint (double wave rings), caps lock chip, unlocking (wave to squircle to disc + "Unlocking"), session picker menu, disk passphrase (solid, no blur) |
| Power | greeting, 5-segment connected group (Lock, Sleep, Log out, Restart, Shut down), unsaved warning pill, key hints | focused action = expanded pill with label and "Press Enter" |
| PowerStates | opens on Lock; focus moves the pill; glass outcome note; countdown (5 s wavy ring, any key cancels); unsaved-work dialog (Cancel/Review/Shut down anyway) | lock and sleep skip countdown |
| Overview | workspace ribbons (thumbs r16), ribbon plate, workspace labels (wave number, name, count), window name pills, focused ring+halo, top search pill, bottom hint pill | scroll workspaces, drag window, type to launch/jump |
| WindowSwitcher | thick glass panel, header (title, meta, "2 of 5"), cards (thumb, app disc, title, workspace), attention dot, "Floating" tag, key hints | selected card (primary-container + ring + scale 1.04); opens after 120 ms hold |
| WindowSwitcherStates* | overflow scroll, same-app cycling, compact tiles (circle to rounded square), private (blurred preview, badge, Alt reveals), type-to-find list | fewer than 9 windows = cards |
| Clipboard | thick glass 2-column panel: search, filter chips, sectioned list rows, preview pane, key hints | selected row = solid primary |
| ClipboardStates* | empty state, sensitive (masked, countdown ring), search results, clear-history dialog, settings rows (keep for 1 h/24 h/7 d, ignore sensitive, keep images) | |
| Screenshot | region frame, thirds, handles, size chip, hint pill, toolbar (mode seg, pointer, timer, video, capture wave) | |
| ScreenshotStates* | window mode (tint + name pill), screen mode (4 px border, monitor chip), record mode (red wave, audio pills), countdown (200 px red wave, 120 px number), after-capture card (thumb, Copied chip, Edit, folder, delete, progress), markup editor (8 tools, swatches, undo/redo, Discard/Copy/Save) | private windows blacked out (Alt includes); Shift = copy only |
| Wallpaper* | preview toast pill, "Colors from X" glass card (swatches, 4 tone strips, contrast note, "Live preview" tag), thick-glass dock (source chips, "Applying to" seg, thumbnail row, add-folder tile, key hints) | selected thumb ring + check; Esc reverts |
| WallpaperStates* | folder source (breadcrumb card), dynamic day/dusk/night schedule, per-display, light-image prompt (Keep Light / Stay Dark), "Reading colors" loading | reduce motion = 200 ms crossfade, no shelf spring |
| Settings* | floating window 1100x760: Mica sidebar 280 (search, nav groups Connect/Devices/Triton/System), solid content (page title, hero preview, 3-way seg, accent list, contrast stops slider, 3 material cards, switches, expressiveness stops slider), "Applying Planet" glass checklist toast | narrow (<860 px): sidebar becomes full-width list, pages slide in |
| SettingsStates* | Displays (monitor arranger, scale stops slider, chip row for refresh rate, switches), Bar & Shell (3 option cards with thumbs, Top/Bottom seg, reveal-delay slider with mono value, switches), Windows (layout preview, gap/radius sliders, preset width chips, focus switches), Keyboard (search, shortcut rows with keycaps and conflict note), search state (results list) | "Settings apply live. No Apply button." |

### 2.3 Concept to component map (what was re-implemented per surface)

| Concept | Where it appears | Library component |
|---|---|---|
| Wave shape (identity) | bar button, avatars, album art, accent swatches, loading, OSD off disc, capture button, overview workspace badge, greeter users | `WaveShape` -> `WaveAvatar`, `Swatch`, `LoadingWave` |
| Icon in tonal circle | list rows, launcher results, notification app icon, QS network rows | `IconDisc` |
| Rounded segmented rows | settings, QS Wi-Fi list, containers, clipboard (different radii), launcher results | `ListGroup` + `ListRow` |
| Filter / source chips | launcher filters, clipboard filters, wallpaper sources, preset widths, refresh rate | `Chip` (+ `ChipGroup`) |
| Connected button group | screenshot toolbar, power menu, settings mode seg, QS? no, Top/Bottom, "Applying to", Day/Week/Month, view toggle | `SegmentedButton` |
| Keycap | launcher footer, wallpaper hints, switcher hints, clipboard hints, power hints, settings shortcuts | `Keycap` (+ `KeyHintBar`) |
| Floating label | overview window names, capture hints, settings "Floating" caption | `Pill` |
| Card | settings, containers, notification, dock | `Card` |
| Slider with stops | QS, settings (contrast, expressiveness, scale, delay), OSD | `Slider` |
| Switch row | settings, QS Wi-Fi header, clipboard settings | `SettingRow` + `Switch` |
| Search field | launcher, clipboard, settings, keyboard shortcuts, overview, switcher type-to-find | `SearchField` |
| Password field | lock, greeter, disk unlock | `PasswordField` |
| Panel / dialog | every glass panel | `Panel`, `Modal`, `Dialog` |
| Preview thumbnail card | switcher, overview, wallpaper, bar workspace preview, screenshot preview | `PreviewTile` |
| Empty state | clipboard, search results, notification centre | `EmptyState` |
| Countdown ring | clipboard sensitive, power, capture | `ProgressRing` (wavy) |

---
## 3. Token layer (task 2)

All of this is emitted by `scripts/generate-theme.py` from an extended
`design/tokens.json` (schema delta in 3.11). Generated singletons replace the
single `Theme.qml`. Values marked **(proposed)** are not on any board; they
are placeholders that need a designer decision (see section 9).

### 3.1 Singletons produced

| Singleton | Contents |
|---|---|
| `Theme` | `mode` ("dark"/"light", resolved), `palette` (current `Palette`), `paletteDark`, `paletteLight`, `reduceMotion`, `batterySaver`, `expressiveness`, `wallpaperLuminance`, `applyUserTokens()` |
| `Palette` (type, not singleton) | 28 colour roles, derived roles (emphasis, veils, scrims, materials, shadows), `ink`. One instance per scheme; `Theme.palette` is the active one |
| `Type` | role table (3.3) |
| `Space` | scale + semantic spacing + `fit()` helpers (3.4) |
| `Size` | control heights, icon sizes, disc/avatar sizes, panel width bounds (3.4) |
| `Shape` | radii, per-corner presets, morph radii, wave path and morph paths (3.5) |
| `Elevation` | shadows and highlights (3.7) |
| `Motion` | springs, roles, timers, loops, reduce-motion (3.9) |
| `Icons` | unchanged (generated from `symbols.codepoints`) |

### 3.2 Colour

**Scheme roles.** The 28 roles in `tokens.json` stay as they are (dark values
verbatim; light values are hand-picked and need matugen regeneration, per
`references/triton/README.md` "Known gaps").

**Derived roles added to `Palette`** (computed in the generator, per scheme):

| Role | Dark | Light | Board source / use |
|---|---|---|---|
| `ink` | `#FFFFFF` | `#191C20` (`rgb(25 28 32)`) | base for every veil and hairline |
| `veilFaint` | ink @ .06 | ink @ .04 **(proposed)** | unselected rows on glass (`rgb(255 255 255 / .06)`), media popover player rows, window switcher unselected cards |
| `veil` | ink @ .10 | ink @ .06 | `--t-veil`; bell button, `.veil` buttons, field fill on glass (`.t-field` .10; board uses .09, .10, .12 in different places, all map here) |
| `veilHi` | ink @ .16 | ink @ .10 | `--t-veil-hi`; hover/pressed veil, `.pn` notification items .09 -> veil |
| `veilStrong` | ink @ .22 | ink @ .14 **(proposed)** | rule-of-thirds lines (.22), divider on glass (.12 to .2) |
| `hairline` | ink @ .12 | ink @ .12 **(proposed)** | window outline `0 0 0 1px rgb(255 255 255 / .12)`, launcher divider .12, menu separator .14 |
| `outlineOnGlass` | ink @ .30 | ink @ .20 **(proposed)** | unselected chip on glass `inset 0 0 0 1px white/.30`, kbd outline .35, dashed "Other..." .5 |
| `scrimSoft` | black @ .30 | black @ .30 | launcher scrim .30; settings backdrop .32; QS demo .25 (snap to .30) |
| `scrimMid` | black @ .35 | black @ .35 | clipboard, switcher (.35) |
| `scrimStrong` | black @ .45 | black @ .45 | dialogs (.45) |
| `scrimCapture` | black @ .50 | black @ .50 | screenshot dim (.5), power menu bg `brightness(.5)` equivalent |
| `emphasisMed` | .80 | .80 | secondary text opacity: board uses .75, .8, .85 on `.s`, meta lines, subtitles |
| `emphasisLow` | .65 | .65 | tertiary: .6, .65, .7 on source lines, timestamps |
| `disabledContent` | onSurface @ .38 | same | all `[disabled]` |
| `disabledContainer` | onSurface @ .12 | same | all `[disabled]` |
| `success` / `onSuccess` | `#8CD6A0` / `#00391B` | `#1B6E3A` / `#FFFFFF` **(proposed)** | call "Accept" (`.pg`); already in current Theme as `successtint`/`onsuccess` but no light value |
| `signalWarn`, `signalInfo` | `#FFC857`, `#6FE0F5` | same | 8 px LED dots only |

`veil` family and scrims are alpha colours (`Qt.rgba`) built in `Palette`; no
other file may build one.

**Media scheme.** Lock, Greeter, Power, Overview, Screenshot and the Login
card sit on a dimmed/blurred wallpaper. These surfaces wrap their content in
`ThemeScope { scheme: "dark" }` so they always read `Theme.paletteDark`
(section 9, Decided). Everything else, including the Wallpaper dock, follows
`Theme.mode`.

**Fixed (scheme-independent) colours:** wave swatch hues (Planet/Hull/Rock/
Shadow/Haze) come from the accent set in `SettingsService`/matugen, not from
the palette. The board's recording red (`#FFB4AB`, i.e. `error`) is a palette
role. The only true literals left in the system are `black` for scrims/shadows
and the swatch/accent data.

### 3.3 Type ramp

One role = family + weight + size + line-height + tracking + case + number
features. `AppText { role: "bodyM" }` is the only way to draw text. Overrides
allowed on `AppText`: `weight` (regular/medium/semibold), `tone` (palette
role), `emphasis` (high/med/low), `elide`, `wrap`, `maxLines`, `tabular`.
Sizes are logical px. Line-height is stored as pixels.

**Jost (display, titles, every numeral)**

| Role | Weight | Size / LH | Tracking | Board sources |
|---|---|---|---|---|
| `displayHero` | 600 | 250 / 230 | -10 px | Lock clock `font:600 250px`. Scales: `min(250, screenH * 0.243)` |
| `displayXl` | 600 | 120 / 120 | -2 px **(proposed)** | Capture countdown number |
| `display` | 600 | 64 / 64 | -1 px | Type board Display; Power greeting; launcher calc result; countdown-ring number; Calculator display (500 there) |
| `displayM` | 600 | 54 / 56 | -1 px | Greeter selected name |
| `displayS` | 600 | 44 / 48 | -0.5 px **(proposed)** | Greeter clock |
| `headlineL` | 600 | 40 / 44 | -0.6 px | Launcher top-hit name; Files folder title; Settings page title (board has weight 500, Q6) |
| `titleXl` | 600 | 34 / 38 | 0 | Lock user name (34), power-state button label focus (32), dialog title (30) |
| `headlineM` | 600 | 28 / 32 | 0 | Type board Headline M; switcher header (500); notification centre title (30, snaps -2) |
| `numeralL` | 600 | 26 / 30 | -0.2 px | Bar clock time, OSD value (tabular), "Unlocking", power-states title |
| `titleDisplay` | 500 | 24 / 28 | 0 | Media popover title, OSD layout code, power-state focus name, QS title (22, +2), call name (22), clipboard empty title (22), wallpaper colours title (20, +4) |
| `numeralM` | 600 | 18 / 22 | 0 | Workspace numbers (17), QS media title (19), avatar initials (derived from avatar size) |

**Google Sans Flex (UI)**

| Role | Weight | Size / LH | Tracking | Board sources |
|---|---|---|---|---|
| `titleL` | 600 | 20 / 26 | 0 | Type board Title L |
| `titleM` | 600 | 16 / 22 | 0 | List titles (500 in `.t-li .t`; weight param), notification names |
| `bodyL` | 400 (500 for row titles) | 16 / 22 | 0 | `.t-li .t` 500, search 16, launcher result title 500 16 |
| `bodyM` | 400 (500 emphasis) | 15 / 21 | 0 | default UI; nav 500 15; menu 500 15; clipboard title 14.5 (+0.5) |
| `bodyS` | 400 | 13 / 18 | 0 | `.t-li .s`, subtitles, meta; 12.5 and 13.5 snap here |
| `caption` | 400 | 12 / 16 | 0 | timestamps, meta lines, 12 px helper text, QS tile sub |
| `micro` | 600 | 11 / 14 | 0 | "Now playing" eyebrow (11), swatch caption (11.5) |
| `labelL` | 600 (500 for chips) | 14 / 20 | 0 | buttons, chips (500), tile labels, seg items, pill |
| `labelM` | 600 (500 tooltip) | 13 / 18 | 0 | small buttons (`.t-btn.s`), text actions ("Clear", "Show 1 more"), switcher card title (13.5, -0.5), tooltip |
| `labelS` | 600 | 12 / 16 | +0.14 em, uppercase | token label_s; `.lbl` group labels; nav label uses .12 em (snaps to .14, Q9) |
| `eyebrow` | 600 | 13 / 18 | +0.14 em, uppercase, primary | `.t-eyebrow`, board section captions (Type/Controls/Containers) |
| `sectionTitle` | 600 | 14 / 20 | +0.02 em, primary, sentence case | Settings `.sec` ("Accent", "Materials", "Autohide") |
| `queryXl` | 500 | 24 / 30 | 0 | Launcher query |
| `fieldDots` | 500 | 22 / 26 | +0.3 em | Password dots |
| `buttonL` | 600 | 16 / 22 | 0 | `.t-btn.l` (16), FAB label (16) |
| `buttonXl` | 600 | 17 / 24 | 0 | `.t-btn.xl` (17) |

**JetBrains Mono**

| Role | Weight | Size / LH | Board sources |
|---|---|---|---|
| `monoM` | 400 | 14 / 24 | terminal, code, hex; size chip (500) |
| `monoS` | 500 | 12 / 16 | kbd (600), timestamps, dimensions, footer, `.cap`; 12.5 and 13 snap here |
| `monoXs` | 500 | 11 / 14 | ring seconds (11) |

Rules: no italics; emphasis moves weight; numerals always Jost or mono; all
tracking in em at the token level (the generator multiplies by size).
Fractional board sizes (11.5, 12.5, 13.5, 14.5) are snapped to the integer
roles above (Q9). Size inside a pill/disc that is itself sized by token is a
fraction of the container (`Avatar` initials = `0.35 * size`), expressed as a
role plus a scale factor in the component, not a literal.

### 3.4 Spacing and sizing

**Scale** (`Space.sN`, N = px): 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24,
28, 32, 40, 48, 56. `tokens.json` lists 4..56 in 10 steps; the boards also use
2 (list gap, connected gap 2/3), 6 (island padding, `.t-seg` inner), 10, 14,
18, 22, 26, 28. Primitives and patterns use the scale directly; surfaces use
semantic aliases only:

| Alias | Value | Meaning |
|---|---|---|
| `Space.hair` | 2 | list gap, connected group gap |
| `Space.gapTight` | 4 | island internal gap |
| `Space.gap` | 8 | default inline gap |
| `Space.gapRow` | 12 | icon + text in dense rows |
| `Space.gapLoose` | 16 | list row content gap |
| `Space.insetControl` | 24 / 16 / 14 | button horizontal padding m / s / text |
| `Space.insetRow` | 20 | `.t-li` horizontal padding |
| `Space.insetCard` | 22 / 20 | `.t-card` padding |
| `Space.insetPanel` | 20 | QS panel padding; 16-22 for others (token per panel kind) |
| `Space.screenMargin` | 16 | floating island inset from screen edge; panel min margin |
| `Space.zoneBar` | 72 | clearance under the bar for drop-down panels (QsWindow uses `y: 72`) |

**Control heights** (`Size.h.*`): `xs 24` (kbd, count badge 20), `sm 32`,
`chip 36` (chip, pill, tooltip is 32, small notification button 36), `md 40`,
`slot 44` (bar slot = bar 56 minus 2 x 6, slider, seg, menu item, tool),
`lg 48`, `field 52`, `xl 56`, `row 64` (list min; clipboard rows 60),
`tile 72` (QS tile, launcher search row), `toolbar 80`. `tokens.json` has
32/40/48/56 + 52 + 64 only; the others are board facts.
Off-ladder single uses to resolve: 34 (OSD "Saver" -> 36 chip), 30 (call/pause
text buttons -> 32 sm), 38 (clipboard disc -> 40 md), 60 (clipboard row ->
64 row; Wi-Fi row 60 -> 64), 62/58 (launcher rows 56 -> xl). Q8.

**Icon sizes** (`Size.icon.*`): `xs 16` (check in thumb), `sm 18` (chip, pill,
small button), `md 20` (button, seg), `ml 22` (nav, list disc, bar), `lg 24`
(default `.t-ms`), `xl 28`, `xxl 32`, `hero 44` (top-hit, power), `heroXl 52`.
The tokens list 18/20/24/28; 16/22/32/44/52 are board facts. Q11 asks for a
binding table (control size -> icon size); the proposal is in each
component's table below.

**Disc / avatar sizes** (`Size.disc.*`): 24, 32, 40, 48, 56, 64, 96, 104
(fingerprint), 150 (greeter). Snaps for single-use sizes: 30 -> 32, 34 -> 32, 38 -> 40, and 44 -> 48 for
discs and avatars (the 44 px bar slot stays `Size.h.slot`).

**Panel width bounds** (`Size.panel.*`) as `{pref, min, max}` plus
`Space.screenMargin`. Width = `min(max, max(min, min(pref, screenW - 2 margin)))`:

| Panel | pref | min | max |
|---|---|---|---|
| QS | 400 | 320 | 440 |
| Notification centre / toast | 440 / 400 | 320 | 480 |
| Launcher (list) | 900 | 560 | 1000 |
| Launcher (calc, commands) | 572 | 440 | 700 |
| Clipboard | 1000 x 780 | 640 x 480 | 1120 x 860 |
| Switcher | 1212 | 480 | screen - 2 margin; row scrolls |
| Dialog | 464 | 360 | 560 |
| Media popover | 440 | 340 | 480 |
| Login card | 420 | 320 | 480 |
| Settings window | 1100 x 760 | 720 x 520 | fill; <860 = narrow layout |

### 3.5 Shape

`Shape` radii (px): `none 0`, `r2` (handles, slider inner), `r4`, `r6` (list
inner, connected-inner variants), `xs 8`, `r10` (chip, tag, notification
tail), `sm 12`, `r14` (clipboard row, tool), `md 16`, `lg 20`, `r22`
(connected end, menu row), `card 24`, `xl 28`, `panelM 32`, `panelL 36`,
`full`. `tokens.json` has 0/8/12/16/20/28/full + list 24/6 + connected 22/8.
Everything else is a board fact. The panel tiers (28 / 32 / 36) are Q4.

Semantic radius presets (what components ask for):

| Preset | Value |
|---|---|
| `Shape.pill(h)` | `h / 2` (always, so it works at any height) |
| `Shape.chip` | 10 (Q4: boards also use 16, 18, 20) |
| `Shape.card` | 24 |
| `Shape.panel.{s,m,l}` | 28 / 32 / 36 |
| `Shape.list{Outer,Inner}` | 24 / 6 |
| `Shape.connected{End,Inner,Gap}` | 22 (24 at size l) / 8 (6 in Controls) / 3 (2 in Controls) |
| `Shape.inner(outer, pad)` | `outer - pad` (concentric rule; clipboard row 14 = 36 - 22) |

**Morph radii** (`Shape.toggled(size)`): s 10 **(proposed)**, m 12, l 14, xl 16
**(proposed)**. **Press radius**: 12 for every button size (`.t-btn:active`).

**Per-corner shapes**: `CornerShape` takes `radii: [tl, tr, br, bl]`. Presets
for `ListGroup` position (first, middle, last, only), connected group position
(first, middle, last), notification tail (`24 24 24 10`; `24 24 24 8` in centre;
`20 20 20 8` for centre items).

**Wave.** `Shape.wavePath` (9 lobes, `0 0 100 100`) plus two sibling paths with
the same vertex count (`squircle`, `disc`) emitted by the generator so
`WaveShape.morph` (0..1..2) can interpolate vertices for the loading morph
(Type/Controls/LoginStates show wave -> squircle (r9 rotated 30 degrees) -> disc).
The generator needs the 3-shape paths; only the wave path exists today.

### 3.6 Materials per mode

**As built (overrides the proposals below).**

- Two compositor classes. Layers named `triton-glass` (bar, quick settings,
  center, toasts, OSD) and the Settings window blur the wallpaper only (`xray`).
  Other shell layers (Thick Glass) blur the windows below.
- Hyprland cuts blur out with a hard edge, so `ignore_alpha` is high (.65 for
  `triton-glass`, .55 for `quickshell`) to keep rounded corners clean. Keep it
  under the lowest fill that has to be blurred.
- Mica and Glass start at the alpha in the table. `Scheme.legible` raises it
  until `onSurfaceVariant` on a veil reaches 4.5:1 over the wallpaper's
  brightest color (dark) or darkest (light), which `ThemeSync` samples. This
  replaces the fixed "adaptive Mica" step.
- Thick is fixed: .90 in both modes, which holds over anything.
- The Solid setting makes all three opaque. There is no separate Glass setting.
- `scripts/check-contrast.py` checks the pairs; give it a compiled
  `tokens.json` to check one wallpaper's palette.

`Material` (foundation) resolves a `kind` against the palette. Fill alpha is
applied to the container tier of the palette; blur parameters are hints for
the compositor/namespace.

| Kind | Dark fill | Light fill | Blur / sat / bright (dark) | Blur / sat / bright (light) | Highlight | Shadow | Use |
|---|---|---|---|---|---|---|---|
| `solid` | `surfaceContainerLow..Highest` @ 1 | same | none | none | none | none | content |
| `mica` | `surfaceContainerLow` @ .72 | @ .78 | 48 / 1.4 / .8, xray | 48 / 1.2 / 1.05 | none | none | chrome, pinned bar, sidebars |
| `glass` | `surfaceContainerHigh` @ .70 | @ .82 | 32 / 1.5 / .85 | 32 / 1.3 / 1.05 | `inset 0 1px rgb(255 255 255 / .14)` | `floating` | bar islands, QS, menus, OSD, toast |
| `thick` | `surfaceContainerHigh` @ .88 | @ .90 | 40 / 1.4 / .8 | 40 / 1.2 / 1.05 | same | `floatingLarge` | launcher, switcher, clipboard, dialogs, wallpaper dock |
| `critical` | `errorContainer` @ .78, blur 32 | `errorContainer` @ .90 **(proposed)** | | | | | critical notification (`rgb(147 0 10 / .78)`) |
| `scrim` | black @ levels in 3.2 | same | none | | | | modal backdrops |
| `veil` | ink @ levels in 3.2 | | | | | | controls on glass/scrim |

Highlight in light is not specified. **Proposed:** `inset 0 1px rgb(255 255 255 / .6)`.

**Adaptive Mica:** `+0.08` alpha (dark) / `+0.06` (light) while
`Theme.wallpaperLuminance > 0.6` (the wallpaper picker's "8% more tint" note).
Needs a luminance value from the engine (matugen run) written into
`tokens.json`; recomputed on wallpaper change.

**Fallbacks:** `Theme.batterySaver` or setting "Fall back to Solid on battery
saver" turns `mica` into `solid(low)`; `glass`/`thick` are unaffected. Contrast
rule: any text on a material that measures < 4.5:1 goes solid; this is a
design-time check, not runtime.

**Compositor mapping (Hyprland).** The current rule blurs all `quickshell`
namespaces. Proposed: one namespace per material class so per-class rules are
possible: `triton-mica` (`xray = true`), `triton-glass`, `triton-thick`,
`triton-solid` (no blur). Fill alpha stays in QML. Hyprland's blur size and
vibrancy are global; saturate/brightness cannot be per material; compensate
by baking the brightness into the fill (dark materials slightly lower fill
value). Q3.

**No glass on glass:** `Material` exposes `inGlass` as a context flag;
children (`Button variant: filled`, `Card`) read it and switch to veil fills
automatically (this implements the `.veil` rule from `components.css` without
every call site saying so). A `Material` nested in a glass `Material` logs a
warning in dev.

### 3.7 Elevation

| Token | CSS source | QML |
|---|---|---|
| `floating` | `0 16px 40px rgb(0 0 0 / .45)` | offset (0,16), blur 40, alpha .45 |
| `floatingLarge` | `0 30px 80px rgb(0 0 0 / .55)` | offset (0,30), blur 80, alpha .55 |
| `raised` | `0 2px 6px rgb(0 0 0 / .5)` | |
| `fab` | `0 6px 16px rgb(0 0 0 / .45)` (Controls); Main extended FAB uses `0 6px 18px / .4` | use Controls |
| `lift` | `0 10px 30px rgb(0 0 0 / .4)` | selected switcher card, wallpaper selected thumb (.45), overview thumbs |
| `focusedWindow` | `0 0 0 3px primary, 0 0 0 6px primary @ .25, 0 14px 40px black @ .5` | overview focused thumb |
| `windowOutline` | `0 0 0 1px ink @ .12` | floating window frames only |
| `highlight` | `inset 0 1px 0 ink-white @ .14` | Glass/Thick top edge |
| `tooltipShadow` | `0 6px 16px rgb(0 0 0 / .4)` | |

Light-scheme shadows are not specified. **Proposed:** alpha x 0.5.
Layer-shell windows do not get compositor shadows; the host window must
include a transparent margin of `ceil(blur + offsetY)` on the sides and
bottom, and its input `mask` covers only the content (`SurfaceWindow` does
this).

### 3.8 State layers

Implemented once in `StateLayer`. Overlay colour = the control's *content*
colour (`on*` of its fill) at the opacity below; for veil-filled controls
(controls on glass) the state steps `veil -> veilHi` instead.

| State | Opacity | Notes |
|---|---|---|
| hover | .08 | Controls board shows .10 on filled buttons; Q7 |
| focus (keyboard) | .10 + ring | ring = 2 px `onSurface`, offset 2 (controls); fields/selection use 2 px `primary` inset (`inset 0 0 0 2px primary`) |
| pressed | .10 + radius to 12 | Controls board `.prs` is .14 |
| dragged | .16 | slider handle, reordered item |
| disabled | content `.38`, container `.12` of onSurface | `rgb(226 226 233 / ...)` |
| selected | container swap (`secondaryContainer` for rows/chips, `primaryContainer` for nav, `primary` for seg/clipboard/switcher), not an overlay | |

Menu hover is `primary @ .16` (Containers `.mi.hov` = `rgb(176 198 255 / .16)`;
Materials board has `rgb(178 203 213 / .16)`: treated as a typo, Q7).

### 3.9 Motion

**Springs** (`[stiffness, dampingRatio]` from `tokens.json`; mass 1). The boards
and the README call them Material 3 Expressive, "cross-checked against
community ports, not the official token page". Derived characteristics
(`wn = sqrt(k)`, `zeta`): for the doc only, to choose reduce-motion fallbacks
and epsilons.

| Token | k | zeta | Overshoot | ~Settle (2 %) | Used for |
|---|---|---|---|---|---|
| `spatialFast` | 800 | 0.6 | ~9.5 % | ~0.24 s | toggles, workspace pill, press/shape morph, OSD enter, selection scale, pill widen |
| `spatialDefault` | 380 | 0.8 | ~1.5 % | ~0.26 s | panels/menus appearing, island drop, list reflow, window resize, QS drill slide |
| `spatialSlow` | 200 | 0.8 | ~1.5 % | ~0.35 s | overview, lock lift/unlock, workspace switch |
| `effectsFast` | 3800 | 1.0 | none | ~0.07 s | hover/press state layers |
| `effectsDefault` | 1600 | 1.0 | none | ~0.10 s | colour, icon fill, text fade, exit fades, blur amount |
| `effectsSlow` | 800 | 1.0 | none | ~0.14 s | wallpaper crossfade, palette swap |

**Implementation.** QML's `SpringAnimation` uses different parameters (spring
constant, damping, mass, epsilon) and does not take a stiffness/damping-ratio
pair. Two options; the proposal is A.
- **A (exact).** `SpringValue` (foundation): a `FrameAnimation` integrating
  `x'' = -k(x - target) - 2 zeta sqrt(k) x'` with the analytic closed-form
  step, stopping when `|x - target| < eps && |v| < eps`. Exposes `value`,
  `target`, `velocity`, `running`. `SpringBehavior { on <prop>; spring: Motion.spatialFast }`
  wraps it for a property of any item. Needs Qt 6.4+ `FrameAnimation`
  (Quickshell 0.3 on Qt 6.8+ is fine).
- B (cheap). Precompute `NumberAnimation { duration, easing.type: Easing.BezierSpline }`
  from the step response of each token. No velocity carry-over on interrupt.

Whichever is chosen, only `Motion` knows. Components say
`Behavior on radius { SpringBehavior { role: "shapeMorph" } }` (role names
below).

**Roles.** A role = which spring drives which property group. `Motion.role(name)`
returns `{ spatial, effects, from, to }`. Roles do not carry durations.

| Role | Spatial spring | Effects spring | Transform | Used by |
|---|---|---|---|---|
| `surfaceEnter` | `spatialDefault` | `effectsDefault` | y +16 -> 0, scale .96 -> 1 about the panel's origin; opacity 0 -> 1 | QS, notification centre, clipboard, switcher, wallpaper dock, dialogs, markup editor |
| `surfaceExit` | none | `effectsDefault` | opacity 1 -> 0, scale 1 -> .98 (no spatial overshoot); unmap on settle | all of the above |
| `surfaceEnterSlow` / `surfaceExitSlow` | `spatialSlow` | `effectsSlow` | full-screen: scale 1.04 -> 1 + opacity; unlock sharpens wallpaper | Overview, Power, Lock lift, Greeter |
| `launcherOpen` | `spatialDefault` | `effectsDefault` | scale from the bar wave button position (origin = button centre) | Launcher (board: "springs out of the bar's launcher") |
| `popoverOpen` / `popoverClose` | `spatialDefault` / none | `effectsDefault` / `effectsFast` | scale .92 -> 1 about anchor point; opacity | bar popovers, menus, tooltips, media popover |
| `islandReveal` / `islandHide` | `spatialDefault` / none | `effectsDefault` | y -(slot+margin) -> 0 | bar islands; pinned strip: height 0 -> bar |
| `toastEnter` / `toastExit` | `spatialDefault` / none | `effectsDefault` | x +24 -> 0 (right) or y +16 -> 0 (bottom centre); stack reflows with `listReflow` | toasts, snack bars |
| `osdEnter` / `osdExit` | `spatialFast` / none | `effectsDefault` | y +16 -> 0, scale .96 -> 1 | OSD |
| `osdMorph` | `spatialFast` | `effectsDefault` | width/height/radius change in place between variants | OSD variant swap |
| `pillMorph` | `spatialFast` | `effectsDefault` | width/height/radius of a pill | media pill widen on hover, workspace dot to pill, left island growing for window title, bar indicator chips, power focus pill |
| `shapeMorph` | `spatialFast` | `effectsDefault` | corner radii | toggle round -> square, press tightens to 12, switcher compact tile circle -> rounded square, QS tile on |
| `stateLayer` | none | `effectsFast` | overlay opacity | StateLayer |
| `colorShift` | none | `effectsDefault` | colour, icon fill, text opacity | all colour changes |
| `selection` | `spatialFast` | `effectsDefault` | scale 1 -> 1.04, ring, shadow lift | switcher selected card, wallpaper selected thumb, overview focused thumb |
| `listReflow` | `spatialDefault` | `effectsDefault` | item y/height; add: opacity + y; remove: opacity then collapse | clipboard rows spring in, notification group expand/collapse, launcher results change in place, QS network list |
| `drill` | `spatialDefault` | `effectsDefault` | x +/-width slide between pages inside one panel | QS Wi-Fi page, Settings narrow-mode pages |
| `crossfade` | none | `effectsSlow` | opacity A -> B | wallpaper change, palette swap, hero image swap |
| `scrim` | none | `effectsDefault` | scrim alpha | modal backdrops |
| `shake` | `spatialFast` (stiffness) with zeta **0.25** (proposed `Motion.shakeZeta`) | none | x kick +/-12 relaxes to 0 | wrong password field |
| `sliderRelease` | none | `effectsDefault` | handle/fill follow external value; while dragging: no animation | Slider |

**Ambient loops** (not springs; time-based; stopped by reduce motion):
`loop.loadingMorph` (wave -> squircle -> disc + rotation; period **(proposed)**
1.6 s), `loop.fingerprintPulse` (two rings, **(proposed)** 1.2 s, offset .6 s),
`loop.indeterminate` (waiting bar, **(proposed)** 1.4 s), `loop.wavyPhase`
(wavy progress phase drift, **(proposed)** 1.2 s per wavelength), `loop.meter`
(3 bars, level-driven, not periodic). Q10.

**Behavioural timers** (`Motion.timing.*`, milliseconds; these are product
behaviour, not animation):

| Timer | Value | Source |
|---|---|---|
| `barRevealDwell` | 120 | BarStates; Settings board default says 150; current shell default 300 (Q5) |
| `barHideDelay` | 600 | BarStates |
| `barFullscreenDwell` | 300 | BarStates |
| `barUrgentPeek` | 4000 | Settings "bar peeks for 4 s" |
| `toast` | 6000 (critical/calls: 0 = sticky); max visible 4 | Notifications |
| `osdHold` | 1200 (battery 6000; mic-off sticky) | OSD |
| `switcherOpenDelay` | 120 | WindowSwitcher |
| `mediaPauseFade` | 120000 | MediaBar |
| `capturePreview` | 5000 | ScreenshotStates |
| `captureCountdown` | 3 (s) video | ScreenshotStates |
| `powerCountdown` | 5 (s) | PowerStates |
| `passwordReveal` | 5000 | LoginStates |
| `sensitiveWipe` | 30000 | ClipboardStates |
| `reduceFade` | 120 | tokens.json `reduce_motion` |
| `wallpaperReduceFade` | 200 | WallpaperStates |

**Reduce motion** (`Motion.reduce`, driven by `Theme.reduceMotion`, plus
`batterySaver` optionally): every `SpringBehavior` degrades to
- spatial properties (position, scale, size, radius): jump (duration 0), except
  where jumping hides state change; in that case the effects fade applies;
- opacity/colour: 120 ms linear (`reduceFade`);
- `surfaceEnter/Exit`: 120 ms fade only (clipboard: "panel itself opens in
  120 ms"; wallpaper: 200 ms crossfade, "shelf cards skip the spring");
- `loop.*`: stopped; `loadingMorph` shows the disc statically; meter static;
  media pill swaps controls without the widen spring (MediaBar rule);
- `shake`: replaced by the error tint + message only.

**Presence** (foundation) is the enter/exit state machine used by all
surfaces: input `present: bool`, `role: "surfaceEnter"`. Outputs
`progress` (0..1 effects), `spatialProgress` (0..1 spatial, may overshoot),
`mapped` (true from `present=true` until exit settles), `settled`.
`SurfaceWindow.visible = presence.mapped`. Interrupts retarget the springs and
carry velocity (this is why the exact `SpringValue` is preferred).

### 3.10 Values on boards that are not in `tokens.json`

(Complete enough to drive the generator; all are listed in the appendix tables
with their snap targets.)

- Type: 250, 120, 54, 44, 34, 32, 30, 26, 24, 22, 19, 18, 17, 15, 14.5, 13.5,
  13, 12.5, 11.5, 11 px; weights 500 on Jost; tracking -10/-2/-1/-0.6/-0.5/-0.2,
  +0.02/.04/.12/.14/.3 em; the 22/24 px query/password sizes.
- Space: 2, 3, 6, 10, 14, 18, 22, 26, 28.
- Heights: 24, 28, 30, 34, 36, 38, 44, 52, 56, 60, 62, 64, 68, 72, 80, 96, 104, 112, 150, 170 (thumb), 200 (hero preview).
- Radii: 2, 3, 4, 6, 7, 9, 10, 14, 18, 22, 24, 26, 30, 32, 36, 40, 48, 70.
- Alphas: .04-.06 faint, .08-.12 veil, .14-.18 strong, .22, .26, .28 (scrollbar thumb `rgb(255 255 255 / .28)` in Settings), .3, .35, .5; text opacities .6 .65 .7 .75 .8 .85.
- Shadows: 0 2 6 .5; 0 6 16 .45; 0 6 18 .4; 0 10 30 .4/.45; 0 14 40 .45/.5; 0 16 40 .45; 0 30 80 .55; 0 32 80 .6 (Settings window); inset 0 1 0 white .12/.14/.2.
- Colours: `#8CD6A0`/`#00391B` (success), `#2458C8`, `#D8DEE8`, `#C0552A`, `#1B2A4A`, `#4FA3A5` (accent swatch seeds, Settings/Wallpaper boards), `rgba(124 49 20 / .8)` (greeter power button = tertiaryContainer @ .8), `rgb(147 0 10 / .72)` and `/.78` (error container @ .72 field, .78 critical card), `#3a3c41`/`#2a2c31` (bell dot ring = effective surface), `rgb(0 10 30 / .2)` .. `/ .25` (lock/greeter/power wallpaper tint), `rgb(0 45 110 / .15)` (disc on selected clipboard row = onPrimary @ .15).
- Backdrop treatments for full-screen media surfaces: `blur(10) brightness(.72) saturate(1.1)` (lock), `blur(12) brightness(.62)` (greeter), `blur(14) brightness(.5)` (overview), `blur(18) brightness(.5)` (power). Proposed token `Material.backdrop.{lock,greeter,overview,power}` = `{blur, brightness, saturate, tint}`; implemented in QML (MultiEffect) because the compositor cannot do it for a Background layer (`docs/audit.md` defect 14).

### 3.11 `tokens.json` v0.2 additions (schema)

```jsonc
{
  "type": {
    "roles": {                       // replaces "scale"
      "bodyM": { "family": "ui", "weight": 400, "size": 15, "line": 21, "tracking": 0, "case": "none", "tabular": false },
      "labelS": { "family": "ui", "weight": 600, "size": 12, "line": 16, "tracking": 0.14, "case": "upper" }
      // ... all roles in 3.3
    }
  },
  "space": { "scale": [2,4,6,8,10,12,14,16,18,20,22,24,28,32,40,48,56], "alias": { "hair": 2, "gap": 8, "gapRow": 12, "gapLoose": 16, "screenMargin": 16, "zoneBar": 72 } },
  "size": { "h": {"xs":24,"sm":32,"chip":36,"md":40,"slot":44,"lg":48,"field":52,"xl":56,"row":64,"tile":72,"toolbar":80},
            "icon": {"xs":16,"sm":18,"md":20,"ml":22,"lg":24,"xl":28,"xxl":32,"hero":44,"heroXl":52},
            "disc": [24,32,40,48,56,64,96,104,150],
            "panel": { "qs": [400,320,440], "launcher": [900,560,1000] /* ... */ } },
  "shape": { "radii": {"r2":2,"r4":4,"r6":6,"xs":8,"r10":10,"sm":12,"r14":14,"md":16,"lg":20,"r22":22,"card":24,"xl":28,"panelM":32,"panelL":36},
             "toggled": {"s":10,"m":12,"l":14,"xl":16}, "press": 12,
             "wave": { "path": "...", "squircle": "...", "disc": "..." } },
  "material": { "dark": { "mica": {"base":"surface_container_low","alpha":0.72}, "...": {} },
                "light": { "...": {} },
                "veil": { "dark": [0.06,0.10,0.16,0.22], "light": [0.04,0.06,0.10,0.14], "ink": {"dark":"#FFFFFF","light":"#191C20"} },
                "scrim": {"soft":0.30,"mid":0.35,"strong":0.45,"capture":0.50},
                "emphasis": {"med":0.80,"low":0.65},
                "backdrop": { "lock": {"blur":10,"brightness":0.72,"saturate":1.1,"tint":"rgb(0 10 30 / .2)"} } },
  "elevation": { "floating": [0,16,40,0.45], "floatingLarge": [0,30,80,0.55], "raised": [0,2,6,0.5], "fab": [0,6,16,0.45], "lift": [0,10,30,0.4], "highlight": {"dark":0.14,"light":0.6} },
  "motion": { "springs": { "spatialFast":[800,0.6], "...": [] },
              "roles": { "surfaceEnter": {"spatial":"spatialDefault","effects":"effectsDefault","from":{"y":16,"scale":0.96}} /* ... */ },
              "timing": { "barRevealDwell":120, "toast":6000 /* ... */ },
              "loop": { "loadingMorph": 1600 },
              "reduce": { "fade": 120 } }
}
```

The generator must fail when a role in a component refers to a missing token
(existing behaviour: `require()`), and gains `--check` coverage for the new
outputs.

---
## 4. Component library (task 3)

Notation. Props are QML property names with types. `tone` is a palette role
name. `size` is `"s" | "m" | "l" | "xl"` unless stated (`Button` adds `"compact"`). "Boards" lists the
board and the CSS class or selector the component is derived from. "Sizing"
states min/max/elide/wrap/grow rules. All components honour `enabled`.
Signals are named; every clickable emits `clicked()` and every toggle emits
`toggled(bool)`. Import root for all of this is `qs.foundations`,
`qs.primitives`, `qs.patterns` (Quickshell `qs.` path imports; verify on the
0.3.0 harness before committing to it, otherwise relative `import "../x"`).

### 4.1 Foundations (20)

| # | Component | Kind |
|---|---|---|
| F1 | `Theme` | singleton (generated) |
| F2 | `Palette` | type (generated) |
| F3 | `Type` | singleton (generated) |
| F4 | `Space`, F5 `Size` | singletons (generated) |
| F6 | `Shape` | singleton (generated) |
| F7 | `Elevation` | singleton (generated) |
| F8 | `Motion` | singleton (generated) |
| F9 | `Icons` | singleton (generated, exists) |
| F10 | `ThemeScope` | Item |
| F11 | `AppText` | Text |
| F12 | `Icon` | Text |
| F13 | `Material` | Item |
| F14 | `StateLayer` | Item |
| F15 | `FocusRing` | Item |
| F16 | `Presence` | QtObject |
| F17 | `SpringValue` + `SpringBehavior` | QtObject / Behavior |
| F18 | `CornerShape` | Item (replaces `RoundedRect`) |
| F19 | `Shadow` | Item |
| F20 | `WaveShape` | Item (replaces `WaveShape`/`WavyRing` shapes) |

Plus `SurfaceWindow` (pattern-level host, 4.3).

**ThemeScope** - Purpose: resolves which `Palette` a subtree uses. Props:
`scheme: "inherit" | "light" | "dark" | "follow"` (default `inherit`),
`readonly palette: Palette`, `readonly inGlass: bool`. A helper
`Scope.of(item)` walks `parent` once at completion, finds the nearest
ThemeScope, and returns its palette; if none, `Theme.palette`. Every primitive
binds colours to `scope.palette.x`. Risk: QML has no context inheritance, so
this is one parent walk per component at creation; measured cost is trivial,
but dynamic reparenting is not supported (document). Boards: none; this is
how the media-scheme surfaces are implemented.

**AppText** - Purpose: the only text element. Props: `text: string`,
`role: string = "bodyM"`, `tone: string = "onSurface"`,
`emphasis: "high"|"med"|"low" = "high"`, `weight: ""|"regular"|"medium"|"semibold"`,
`tabular: bool`, `elide: bool = true`, `wrap: bool = false`, `maxLines: int = 1`,
`scale: real = 1` (display roles only). Derives family/size/line/tracking/case
from `Type`. Resolves bundled static font names ("Jost SemiBold", per
conventions: names, not weight matching). Uppercase and tracking applied here.
Sizing: `implicitWidth` from content, `Layout.fillWidth` friendly, elides by
default, `wrap` uses `Text.WordWrap` with `maxLines`; display roles accept
`fit: true` which shrinks via `fontSizeMode` to a `minimumRole`.
Replaces `TritonText` (keep its enum idea of family; drop `boxHeight` - the
role's line height centres glyphs).

**Icon** - Purpose: Triton Symbols glyph. Props: `glyph: string` (from `Icons`),
`size: string = "lg"` (`Size.icon.*`), `fill: bool`, `tone`, `emphasis`. Box
is square `Size.icon[size]`; glyph centred. Replaces `TritonIcon`
(`size: real = 22` -> token). Filled variant uses the filled font. Boards:
`.t-ms`, `.t-ms.f`.

**Material** - Purpose: paints a surface material. Props:
`kind: "solid"|"mica"|"glass"|"thick"|"critical"|"scrim"|"veil"|"none"`,
`tier: "low"|"container"|"high"|"highest"` (solid only),
`radius` (via `Shape` preset name or `radii` array), `elevated: bool`
(per kind default), `adaptive: bool` (mica), `outlined: bool` (window outline),
`readonly inGlass: bool`. Draws fill (palette + alpha), the top highlight,
shadow via `Shadow`, optional `hairline`. Exposes the compositor namespace hint
(`namespaceHint`) for `SurfaceWindow`. Boards: `.t-solid .t-mica .t-glass
.t-thick .t-window-floating`, Materials, Containers. Motion: `colorShift` when
mode changes. Light: values from `Palette`, never from white-alpha.

**StateLayer** - Purpose: hover/press/focus/drag/disabled overlay. Props:
`hovered`, `pressed`, `focused`, `dragged`, `disabled`: bool; `color` (the
content colour of the host); `veil: bool` (step through veil levels instead);
`radius` (follows host `CornerShape`). Reads `Palette.state*`. Motion:
`stateLayer`. Boards: `.hov .foc .prs .dis` in Controls; components.css.

**FocusRing** - Purpose: keyboard focus indicator. Props: `visible`, `kind:
"outside" | "inset"`, `tone: "onSurface" | "primary"`. 2 px, offset 2 (outside)
or inset. Only shown for keyboard focus (`activeFocus` after key event).

**Presence** - see 3.9. Props: `present: bool`, `role: string`,
`origin: point` (for scale origin), `readonly progress, spatialProgress, mapped,
settled`. Used with a `Transform` helper `PresenceTransform { presence; }`
(scale + translate + opacity from the role's `from` values).

**SpringValue / SpringBehavior** - see 3.9. Props: `spring: var` (a Motion
token pair) or `role: string`, `epsilon`. `SpringBehavior` is a `Behavior`
subtype: `Behavior on width { SpringBehavior { role: "pillMorph" } }`.

**CornerShape** - Purpose: rectangle with per-corner radii, animatable.
Props: `radii: [tl,tr,br,bl]` or `radius` (uniform), `color`, `border` (width,
colour; inset), `gradient`. Implemented with `Shape`/`ShapePath` (existing
`RoundedRect` does this) or `Rectangle` when uniform (cheaper; auto-chosen).
Corner changes go through `shapeMorph` when `animated: true`.

**Shadow** - Purpose: elevation token to `MultiEffect`/`RectangularShadow`.
Props: `level: "raised"|"floating"|"floatingLarge"|"fab"|"lift"`, `radius`.

**WaveShape** - Purpose: identity shape from `Shape.wavePath` (9 lobes) with
fill, optional stroke, optional glyph/text centred, and `morph: real` (0 wave,
1 squircle, 2 disc) plus `spin: bool`. Props: `size` (disc ramp), `fill` tone,
`stroke`, `strokeTone`, `glyph`, `glyphTone`, `text`, `morph`. Boards: launcher
wave, album art, avatars, swatches, OSD off-disc, capture button, greeter users,
loading. Replaces `WaveShape`.

### 4.2 Primitives (34)

Layout-less leaf components: no service imports.

**P1 Button**
- Purpose: text (+ optional icons) action. Props: `text`, `icon`, `trailingIcon`,
  `variant: "filled"|"tonal"|"outlined"|"text"|"elevated"|"veil"|"glass"|"danger"|"success"`,
  `size`, `toggle: bool`, `checked: bool`, `loading: bool`, `fullWidth: bool`.
  Signals `clicked`, `toggled`.
- Metrics: compact 36 / pad 16 / `labelM` / icon sm / radius 18 (the notification and OSD action size, Q8); s 32 / pad 16 / `labelM` / icon sm / radius 16; m 40 / pad 24 / `labelL` / icon md / radius 20 (text variant pad 14); l 48 / 28 / `buttonL` / icon md / 24; xl 56 / 32 / `buttonXl` / icon lg / 28. Gap `Space.gap`.
- Variants: filled `primary/onPrimary`; tonal `secondaryContainer/onSecondaryContainer`; outlined transparent + 1 px `outline` ring + `primary` text; text transparent `primary`; elevated `surfaceContainerLow` + `raised` + `primary` text; veil `veil` fill + `onSurface`; glass `Material glass` (greeter session/layout, `t-btn t-glass`); danger `errorContainer/onErrorContainer`; success `success/onSuccess` (call accept). In an `inGlass` scope, `filled` stays, `tonal`/`elevated` auto-become `veil`.
- States: rest, hover (+StateLayer), focus (ring), press (radius -> `Shape.press` 12), disabled (container .12, content .38), toggled (`checked`: round -> square via `Shape.toggled`; unselected toggle = `tonal`-neutral `surfaceContainerHighest`).
- Motion: `stateLayer`, `shapeMorph` on press/checked, `colorShift`.
- Boards: Controls `.b .filled .tonal .outl .text .elev .s .l .xl`, components.css `.t-btn`, Notifications `.pf .pt .pe .pg` (36 px: `compact`), OSD Saver pill (34 -> `compact`), Screenshot `.t-btn l veil`, Greeter `.t-btn t-glass`.
- Sizing: height fixed by size; width = content + padding; `fullWidth` fills; label elides (`labelL`), min width = height.

**P2 SplitButton** - `Button` + `IconButton` joined (ends 20/6, gap 2). Props: `text`, `icon`, `variant`, signal `menuRequested`. Boards: Controls "split".

**P3 IconButton**
- Props: `icon`, `iconChecked` (optional), `variant: "standard"|"filled"|"tonal"|"outlined"|"neutral"|"veil"`, `size: "s"|"m"|"l"` (+`"slot"` 44 for bar, `"xl"` 56), `toggle`, `checked`, `badge: Badge?`, `fillIcon: bool`.
- Metrics: s 32 / r16 / icon sm(18); m 40 / r20 / icon md(20, boards 22 in bars: `ml`); l 48 / r24 / icon lg(24); slot 44 / r22 / icon ml; xl 56 / r28.
- States and morph: same as Button. Toggled radii `Shape.toggled(size)`.
- Boards: `.t-ibtn` + `.filled .tonal .outlined .neutral .veil .l .s .toggled`; bar bell 44; QS gear (veil); screenshot `ibtn l veil`; preview card folder/delete (veil).
- Sizing: square, fixed.

**P4 Fab** - Props: `icon`, `text` (extended), `size: "s"|"m"|"l"`, `tone: "primaryContainer"`. s 40 r12, m 56 r16, l 96 r28, extended h 56 r16 pad `0 22 0 18`. `fab` shadow. Boards: Controls `.fab`, Main extended FAB. Used by: nothing in the shell today (Files app only); kept for completeness (ComponentIndex lists it implicitly). **Optional; do not build until needed.**

**P5 SegmentedButton** (connected group)
- Props: `model: [{id, text, icon}]`, `currentId`, `size: "m"|"l"|"xl"`, `variant: "standard"|"veil"`, `layout: "row"|"column"`, `shape: "pillEnds"|"squareEnds"` (power menu variant), `expandedId` (power focus pill).
- Metrics: item height 44 (m) / 48 (l); padding 20; gap 3 (`Shape.connectedGap`); ends `Shape.connectedEnd` 22/24, inner 8; selected item: `primary/onPrimary` and fully round (Controls "selected is full"); unselected `surfaceContainerHigh` (standard) or `veil` (veil).
- Power menu variant: items 140 x 140 column icon+label, ends 70, inner 14, gap 6; focused item becomes expanded pill w 300 r70 horizontal (`pillMorph`); per-item `tone` (container pair). Compact power-states: 96 x 96, focused 210 wide.
- Motion: selection change `shapeMorph` + `colorShift`; width of focused item `pillMorph`.
- Boards: `.t-seg .t-seg.l .t-seg.veil`; Settings Dark/Light/Auto (`.t-seg` 3 items with icons); Settings Top/Bottom; Wallpaper "Applying to"; Controls Day/Week/Month; Power `.btn`; Screenshot Region/Window/Screen.
- Sizing: `fill` distributes equally; min item width = content; labels elide.

**P6 Chip** (filter/input/assist)
- Props: `text`, `icon`, `selected`, `removable` (trailing close), `variant: "outlined"|"veil"`, `shape: "square"|"round"` **(open Q4)**, `size: "m"|"s"`.
- Metrics: h 36, pad 14, radius `Shape.chip` 10 (round: pill), `labelL` weight 500, icon sm. s: h 32 r16 (Controls chips).
- Variants: outlined (1 px `outline`) / veil (on glass: `outlineOnGlass` ring). Selected: `secondaryContainer/onSecondaryContainer`, no ring (clipboard + launcher "All"); Wallpaper source tabs: selected `primary/onPrimary` 40 high round -> that is a `SegmentedButton`-like pill; mapped to `Chip { size: "m", shape: "round", selectedTone: "primary" }` **(new `selectedTone`)**.
- Motion: `colorShift`.
- Boards: `.t-chip .on`, Launcher filters, Clipboard filters, Controls chips, Wallpaper sources, Settings 60 Hz/120 Hz/VRR, preset widths.
- Sizing: content width, `ChipGroup` wraps (`Flow`) or scrolls.

**P7 Pill** (floating label, not interactive) - Props: `text`, `icon`, `tone`, `material: "glass"`. h 36, r18, pad `14 / 10`, `labelL`, icon sm. Boards: `.t-pill` overview window names, capture hints, markup audio pills, settings floating caption. Sizing: content width, `maxWidth` elides.

**P8 Tag** - Props: `text`, `tone: "tertiaryContainer"|"secondaryContainer"|"scrimDark"`. `labelS` weight 600, pad `3 10`, r10. Boards: `.t-tag` ("Live preview", "Work", "Commands" in launcher, switcher "Floating" black/.55).

**P9 Badge** - Props: `kind: "dot"|"count"`, `count`, `ringTone` (the surface behind, so the ring matches: replaces `#3a3c41`/`#2a2c31` literals). dot 10 r5 `tertiary`, ring 2; count min 20 x 20 r10 `labelS`-bold on `onTertiary`. Sizing: count grows with digits, "9+" cap.

**P10 Keycap** - Props: `text`, `variant: "outline"|"raised"`, `tone: "onSurface"|"onMedia"`. outline: min 24 x 24 r7 pad 6 `monoS` 600, ring `outlineOnGlass`; raised: min 30 x 30 r8 pad 9 `monoS`, `surfaceContainerHigh` + bottom inset shadow (`kc`). Boards: `.t-kbd`, `.kc u`, `.kb u`.

**P11 Switch** - Props: `checked`, `showCheck: bool = true`. Track 52 x 32 r16; off: `surfaceContainerHighest` + 2 px `outline`, thumb 16 r8 `outline` at (6,6); on: `primary`, thumb 24 r12 `onPrimary` at (22,2) (components.css; Controls says 23,4: Q7) with check icon 16 `primary`. Motion: thumb `spatialFast` (size, position), colours `colorShift`. Press enlarges thumb (**proposed** 28). Sizing: fixed. Boards: `.t-switch`, Controls.

**P12 Checkbox / P13 Radio** - 24 x 24, box r6 (2 px `outline`), checked `primary` + check 18 (wght 700) `onPrimary`; radio r12, inner 12 `primary`. Touch target 40 via padding. Boards: Controls only (no shell surface uses them yet).

**P14 Slider**
- Props: `value: real (0..1)`, `from`, `to`, `stops: int` (0 = none), `snap: bool`, `icon` (inside active track), `variant: "standard"|"small"|"range"|"centered"|"pill"|"osd"`, `valueText` (mono/Jost label), signals `moved(real)`, `pressedChanged`.
- Metrics (standard / `.sld`, `.t-slider`): height 44; track 16 high; active `primary` with radii `8 2 2 8` (outer 8 `Shape.r8`, inner `r2`); inactive `surfaceContainerHighest` `2 8 8 2`; handle 4 x 44 r2 `primary` with a gap of 6 either side (`calc(x - 6px)` track ends); stops 4 x 4 r2: `onPrimary` on the active side, `primary` on the inactive side, vertically centred. small: 28 high; range: 16 high with two handles; centered: 28 high fills from 50 %; pill (QS in Main): track 52 r26 `veil`, active full-height `26 4 4 26` containing leading icon, handle 4 x 60 overhanging 4 px; osd: 16 high r8 `veil` track, active `8 3 3 8`, handle 4 wide overhanging 5 px.
- States: rest, hover (handle widens to 6? **not specified**; none), pressed/dragging (handle follows pointer; no animation), focus (keyboard arrows +/- 5 %, ring on handle), disabled. External value change: `sliderRelease`.
- Boards: `.t-slider`, `.sld .a .b .h .d`, Controls `.sl`, QS Main pill sliders, OSD `.trk`.
- Sizing: fills width; `Layout.minimumWidth` 120; row layouts give 260 fixed in settings (`Size.slider.row`), which becomes `fillWidth` with `maximumWidth: 320`.

**P15 ProgressBar** - Props: `value` (0..1) or `indeterminate`, `variant: "wavy"|"flat"`, `tone`, `running: bool`. wavy: amplitude 3, wavelength 24, stroke 4 round, played part wavy, remainder flat `secondaryContainer` (or `veilStrong` on glass); flat: 8 high r4; waiting: two segments (30 % and 14 %) sliding. Motion: `loop.wavyPhase`. Boards: Controls, MediaBar popover progress (396 wide), Notifications progress, downloads.

**P16 ProgressRing** - Props: `value` or `indeterminate`, `size`, `thickness`, `tone`, `trackTone`, `variant: "wavy"|"round"`, `text` (centre, mono or Jost). 9-lobe wavy ring (amplitude ~1.1 at 34); countdown variant drains over `duration` (time-based). Boards: Clipboard sensitive ring 34 (mono 11), power countdown 132 (Jost 64), battery as wavy ring (Settings "Battery as wavy ring"). Replaces `WavyRing`.

**P17 LoadingWave** - `WaveShape` with `spin`, `morph` loop. Sizes 40 (controls), 96 (unlocking, proposed). Boards: Controls, LoginStates "Unlocking".

**P18 TextField** - Props: `text`, `label`, `placeholder`, `error`, `helper`, `leading`, `trailing`, `echoMode`, `kind: "filled"|"underline"`. Controls `.fld`: h 56 r16 `surfaceContainerHighest`, label `caption` -> floats; focus = `inset 0 0 0 2px primary`, label `primary`; error = ring+label `error`, helper `caption` `error`. Text 16 `bodyL`. Sizing: fillWidth, h fixed.

**P19 SearchField** - Props: `text`, `placeholder`, `leading` (default search icon), `trailing` (mic / hint keycap / clear), `size: "m"|"l"|"launcher"`, `tone: "veil"|"solid"`. m: h 52 r26 pad `0 18` gap 12 `bodyL`, fill `veil` (on glass) or `surfaceContainerHighest` (solid, Controls). launcher: h 72, text `queryXl`, leading `WaveAvatar` 40 (icon). Signals: `accepted`, `textEdited`, `escape`, `navigate(dir)`. Boards: `.t-field`, Launcher search row, Clipboard (trailing "Super+V"), Settings sidebar (52, margin `24 0 4`), Keyboard shortcuts search, Overview top pill (h 56 r28 glass, leading 36 wave), switcher type-to-find.

**P20 PasswordField** - Props: `text` (never bound out), `state: "idle"|"typing"|"wrong"|"fingerprint"|"busy"`, `capsLock`, `revealed`, `message`, `submitEnabled`, signals `submitted`, `revealToggled`. h 56 (Greeter 60/ r30), r28, pad `0 8 0 18`, gap 12: lock icon, dots (`fieldDots`) or text, eye `IconButton s`, go button 44 round `primary` + `arrow_forward`. States: idle quiet, go disabled (`disabledContainer`); typing: ring 2 `primary`, go filled; wrong: `shake`, clears, fill `errorContainer` @ .72, ring `error`, message `labelM` `onErrorContainer` with error icon; busy: go -> `LoadingWave` small. Caps-lock chip lives in the pattern (`LoginCard`). Boards: Lock, Greeter, LoginStates, disk passphrase.

**P21 Avatar / WaveAvatar** - Props: `size`, `initials` or `icon` or `source`, `tone: "tertiaryContainer"|"primary"|"secondaryContainer"`, `selected`, `ring`. Wave-clipped; initials `Jost 600` at `0.35 * size`. Sizes 32/40/48/56/96/150. Boards: Controls, Notifications (`MK` 48), Lock (96), Greeter (96/150 selected, ring stroke 1.8 + scale 1.12), Overview number badge 56, album art 40/44/112/56.

**P22 Swatch** - `WaveShape` filled with an accent; `checked` overlays a `check` 28 white (Planet). 64 px in Settings (label below `labelM`), 40-ish in Wallpaper colours card (label `micro`). "Custom" = dashed/ring variant (`outline` 2 px circle + add icon). Boards: Settings `.accent`, Wallpaper "Colors from Orbit" card.

**P23 IconDisc** (`t-ic`) - Props: `icon`, `size: "m"|"l"|"xl"` (40/48/56), `tone: "secondary"|"primary"|"tertiary"|"error"|"surfaceHighest"|"veil"`, `fillIcon`. Circle, icon `ml` at m. Replaces `ContentRow` + ad-hoc discs. Boards: `.t-ic`, launcher result icons (40 with tint variants), notification app icon (48), QS network (disc 40).

**P24 ListRow**
- Props: `title`, `subtitle`, `leading` (Component or `icon`), `trailing` (Component), `selected`, `interactive`, `position: auto|first|middle|last|only` (set by `ListGroup`), `density: "regular"|"compact"|"dense"`, `tone: "container"|"onCard"|"veil"`.
- Metrics: regular: min h 64, pad `12 20`, gap 16, `bodyL` weight 500 title + `bodyS` `emphasisMed` subtitle (margin-top 1), radius from position (24/6). compact: h 56 r20 pad `0 12 0 8` gap 14 (launcher result rows); dense: h 48 (menu items, r22).
- Fill: `tone: container` -> `surfaceContainer`; on a `Card` auto-steps to `surfaceContainerHigh` (the `.t-card .t-li` rule); on glass -> `veilFaint`; selected: `secondaryContainer/onSecondaryContainer` (subtitle inherits at .8) or `primary/onPrimary` (clipboard) via `selectedTone`.
- States: hover, press, focus ring (inset), selected, disabled.
- Motion: `colorShift`, `shapeMorph` (corner roles change when group reorders).
- Sizing: fills width; title elides (`maxLines 1`), subtitle `maxLines 2` in settings, 1 in lists; trailing keeps its natural width; the text block is `Layout.fillWidth` with `minimumWidth 0`.
- Boards: `.t-li`, Containers lists, Settings rows, QS Wi-Fi rows (h 60, r `22/6`), Clipboard rows (h 60, r14, selected r28 - becomes `density: compact` + `shape: "soft"`), Launcher rows, Notification centre items (`.pn` r `20 20 20 8` - handled by `NotificationCard`).

**P25 ListGroup** - Column with `Space.hair` gap, assigns `position` to children (first/middle/last/only), clips radius. Props: `title` (SectionHeader), `model`/children. Replaces the per-panel list code (SettingRow lists). Outer radius 24 (card) or 22 (QS list).

**P26 Card** - Props: `variant: "filled"|"tonal"|"outlined"|"glass"`, `padding: "card"|"compact"|"none"`, `selected`, `interactive`. filled `surfaceContainerLow` r24 pad `22 / 20`; tonal `secondaryContainer`; outlined 1 px `outlineVariant`; glass = `Material glass`. Sets `ThemeScope` context so `ListRow` steps up a tier. Selected (settings material cards, option cards): `secondaryContainer` + ring `outlineVariant` off. Boards: `.t-card`, Containers `.card`, Settings material/option cards, Bar & Shell option cards.

**P27 SectionHeader** - Props: `text`, `kind: "eyebrow"|"sectionTitle"|"navLabel"|"groupLabel"`, `trailing`, `action`. `eyebrow` (13, primary, caps), `groupLabel` (`labelS` `onSurfaceVariant` @ .8 caps, pad `12 12 6`), `navLabel` (same, pad `18 16 6`), `sectionTitle` (14 primary sentence case, pad `28 8 10`). Boards: `.t-eyebrow`, `.lbl`, `.t-nav-label`, Settings `.sec`.

**P28 Divider** - Props: `orientation`, `inset`, `fade: bool` (fades to transparent at list ends), `tone: "outlineVariant"|"hairline"`. 1 px. Boards: Containers, Launcher (hairline), menu separators (inset 14, margin 6), bar title divider (1 x 28 `veilStrong`).

**P29 Tooltip** - Props: `text`, `target` (item), `delay` (**proposed** 600 ms). h 32 r12 pad `0 12` `labelM` 500, material glass @ .85 + highlight + `tooltipShadow`. Motion: `popoverOpen` (compact). Boards: Controls tooltip.

**P30 ScrollArea** - Props: `contentWidth`, `contentHeight`, `fadeEdges: bool`, `autoHide`. Scrollbar: 4 px thumb (r2, `onSurface` @ .5) at rest, 10 px (r5, .75) on hover/drag, auto-hide, 6 px in Settings (thumb `ink` @ .28). Edge fade `linear-gradient(transparent, surface)` 60 px (Settings content). Boards: Containers scrollbar, Settings, switcher overflow, Clipboard list. Replaces raw `Flickable`/`ListView` scroll plumbing in surfaces.

**P31 Tabs** - Props: `model`, `currentId`. Underline tabs h 44 pad `0 18` `labelL`; active `primary` + 3 px indicator (r `3 3 0 0`, inset 12). **P32 NavItem** - Props: `text`, `icon`, `selected`, `variant: "sidebar"|"rail"`. sidebar: h 48 r24 pad `0 16` gap 16 `bodyM` 500; selected `primaryContainer/onPrimaryContainer` weight 600 icon `onPrimaryContainer`; rail: 72 wide, 56 x 32 `secondaryContainer` pill + label `labelS`-ish 12 600. Boards: `.t-nav`, Controls `.tab .rail`, Settings sidebar, Files sidebar (`.nav.on` secondaryContainer: variant `tone: "secondary"`), QS handoff sidebar.

**P33 PreviewTile** - Props: `source` (image/window thumbnail), `title`, `subtitle`, `icon`, `selected`, `badge`, `ratio`, `radius`, `size`. Thumbnail with inset 1 px `veil` hairline, caption row (app disc 32 + `labelM` title + `caption` workspace). Selected: `primaryContainer` bg + 3 px `primary` ring + `lift` + scale 1.04 (`selection`). Boards: Switcher cards (220 w, pad 10, r24, thumb 200 x 124 r14), Wallpaper thumbs (200 x 120 r20, selected ring 3 + check badge 28), Overview thumbs (r16), Bar workspace preview thumbs (150 x 150 r14), Settings option cards. Privacy: `private: bool` -> blurred thumb + `visibility_off` badge.

**P34 LevelMeter** - Props: `levels: [real]` or `active`; 3 bars 3 x (7..16) r2 `primary`. Boards: media pill. `loop.meter`.

### 4.3 Patterns (26)

Compositions of primitives with behaviour. Patterns may use `Presence` and
`Motion`; they still do not import services.

**T1 SurfaceWindow** - The only place a Quickshell window is created.
Wraps `PanelWindow` (layer shell) or `FloatingWindow`. Props: `presence`,
`layer`, `anchors`, `margins`, `contentItem`, `exclusive: bool`,
`keyboard: "none"|"onDemand"|"exclusive"`, `namespace` (derived from the
content `Material` kind: `triton-glass` etc.), `screen`, `follow: "focused"|"all"`.
Automatically: sizes the window to content + shadow margin + overshoot
margin, sets `mask: Region { item: content }`, binds `visible: presence.mapped`,
handles Esc and click-outside (`dismissOnOutside`) and focus grabbing.
Replaces the repeated `PanelWindow` boilerplate in `QsWindow`, `CenterWindow`,
`ClipboardWindow`, `PowerWindow`, `OverviewWindow`, `WallpaperWindow`,
`OsdWindow`.

**T2 Panel** - Material container with a radius tier and padding scale.
Props: `material: "glass"|"thick"|"solid"|"mica"`, `radiusTier: "s"|"m"|"l"`,
`padding: "none"|"s"|"m"|"l"`, `width: {pref,min,max}` (by `Size.panel.*` key),
`title`, `headerTrailing`. Applies `ThemeScope inGlass`, width clamping via
`Space.fit`, `PresenceTransform` (role passed in). Boards: all glass/thick panels.

**T3 Popover** - `Panel` anchored to a point/item (bar buttons): `anchorItem`,
`placement`, `arrow: false`. Role `popoverOpen/Close`. Keeps `BarState.hold`
while open. Boards: BarStates popovers, MediaBar popover.

**T4 Modal / T5 Dialog** - `Modal`: scrim (`scrimSoft/Mid/Strong` by `level`),
click-outside and Esc dismiss, focus trap. `Dialog`: `Modal` + `Panel thick`
(w 464 pref, r28, pad `28 28 22`), props `icon`, `title` (titleXl or headlineM),
`body`, `actions: [{text, variant, role}]`, `destructive`. Destructive confirm is
`Button variant: danger`. Boards: Containers dialog, Clipboard clear history,
PowerStates unsaved-work (w 520).

**T6 Menu / MenuItem / MenuSeparator** - Glass r28 pad 10, items h 44-48 r22-24 pad `0 14-16` gap 12-14 `bodyM` 500 icon `ml`, trailing key hint `monoS`; hover `primary @ .16`; danger tone `error`; check mark for current; submenu chevron. Props: `model`, `anchor`. Boards: Containers menu, Materials `.mi`, LoginStates session picker (w 260). Role `popoverOpen`.

**T7 Island** - Props: `material: "glass"|"mica"` (follows bar mode), `leading/default content`. h `Size.h.slot + 12` = 56 (`Theme bar height` token = `Size.bar`), r28, pad `0 6`, gap 4. Children vertically centred by Row alignment (existing `ContentRow` idea: `Row` with `Layout.alignment`). Width animates with `pillMorph`. Boards: `.isl`, `.t-island`.

**T8 StatusPill** - Props: `tone: "primaryContainer"|"tertiaryContainer"|"errorContainer"`, `items`. h 44 r22 pad `0 18` gap 16; icons `ml`; the tone is picked by the service state (ok / attention / urgent). Boards: `.stat`, BarStates indicators (also recording chip: `Pill`-like with inner stop button).

**T9 Toast** - Props: `text`, `actionText`, `icon`, `timeout`. Glass h 56 r28 pad `0 10 0 24` gap 22 `bodyM` 500, trailing text `Button`. Role `toastEnter/Exit`. Boards: Containers toast; Settings "Applying Planet" (is a `ChecklistToast`: glass r28 w 230 pad `20 22` with `ListRow dense` of check_circle rows).

**T10 NotificationCard** - Props: `kind: "standard"|"message"|"critical"|"progress"|"call"|"screenshot"`, `appIcon`, `avatar`, `title`, `body`, `time`, `actions`, `progress`, `thumbnail`, `context: "toast"|"center"|"stack"`, `lockHidden`. Radii `24 24 24 10` (toast) / `24 24 24 8` / `20 20 20 8` (centre item) / stacked collapsed `20 20 20 8`. Toast: `Material glass`, pad `14 16 14 14`, gap 14, avatar 48; critical: `Material critical`, inverted buttons; message: inline reply `TextField`-pill h 36 r18 `veil` + send `IconButton` 36 filled; progress: `ProgressBar wavy` + percent `caption` + Cancel; call: 56 avatar, `titleDisplay` name, split Decline/Accept `Button` h 40 flex; screenshot: 88 x 60 r12 thumb + Open / Show in Files. Hover pauses its timer (signal `hoverChanged`). Sizing: width fixed by container (400 toast / 440-32 centre), body `maxLines` 2 toast / 3 centre.

**T11 NotificationGroup** - Header (`IconDisc` 32, name `titleM`, count `caption`, chevron, "Clear" `labelM` primary) + stacked cards (collapsed peek: offset 12 inset at .5). Role `listReflow`. Boards: `.grp`, `.pn`.

**T12 Dock / Shelf** - Bottom-docked thick glass bar with header row and a horizontal `ScrollArea` of `PreviewTile`s. Wallpaper picker. Radius `panelL`, pad `22 26 20`, inset `Space.screenMargin 40 / bottom 24`. Props: `header`, `model`, `delegate`, `footer` (key hints). Boards: Wallpaper `.t-thick` bottom dock.

**T13 SidebarNav** - Mica column w 280 (200 in QS hand-off, full-width list <860): `SearchField` (52, margin `24 0 4`) + `NavItem` groups with `SectionHeader navLabel`; arrow keys. Props: `groups: [{label, items}]`, `currentId`, `collapsed`. Boards: Settings sidebar.

**T14 TileGrid + Tile** - Grid with `columns` (default 2), gap 8. Tile: h 72, pill r36 (`Shape.pill`), pad `0 10 0 12` gap 12: icon `lg`, label `labelL`, sub `caption` @ med, trailing chevron `ml` when `drillable`. Off: `veil`; on: `primary/onPrimary`; shape morph on = r20 (Main) vs r36 (QS board): `onShape: "square"|"pill"` Q1. Props: `icon`, `label`, `subtitle`, `checked`, `drillable`, signals `toggled`, `drilled`. Boards: `.tile`, QS.

**T15 EmptyState** - `WaveShape` 88 @ `veil` + `titleDisplay`/`titleM` + `bodyM` @ med (`maxWidth` 360, centre). Boards: Clipboard empty, search "no results", Notification centre empty (not on a board; same pattern).

**T16 KeyHintBar** - Row of (`Keycap` + `bodyS` label) pairs; `items: [{keys: [..], label}]`; wraps (`Flow`) when narrow; `tone: "onSurface"|"onMedia"`; separator spacing `Space.gapLoose`. Boards: Launcher footer, Wallpaper, Switcher, Clipboard, Power, Capture hint pill, Overview bottom pill.

**T17 SettingRow** - `ListRow` with `IconDisc` and one control slot: `control: "switch"|"slider"|"segmented"|"chips"|"value"|"chevron"|"button"|Component`. Value text `monoS` (reveal delay "150 ms"). Props: `title`, `subtitle`, `icon`, `checked`, `value`, `model`... Boards: Settings rows. Sizing: control column max 260-320; below `Size.breakpoint.narrow` the control wraps under the text.

**T18 SettingsPage** - Scroll container with page header (`headlineL` title + `bodyM` subtitle @ med), sections (`SectionHeader sectionTitle` + `ListGroup`), bottom edge fade, 32 px side padding. Props: `title`, `subtitle`, default content. Boards: Settings pages.

**T19 PlayerCard** - Props: `art`, `title`, `artist`, `source`, `position/length`, `playing`, `shuffle`, `repeat`, `volume`; layout variants: `popover` (w 440 r32: 112 wave art, `titleDisplay`, wavy progress, transport with 64 wave play, volume `Slider`), `qs` (card r24 pad 16, 56 art, `micro` "Now playing", `numeralM` title, prev/next, 56 x 48 play r16), `lock` (pill w 360 h 64). Boards: MediaBar, Main QS media card, Lock media pill.

**T20 MediaPill** - Island sub-pattern: art 40 wave, title `labelM` + artist `caption` @ med (max 200, elide), `LevelMeter`, transport `IconButton m` (play filled). States: playing, hover (widen with prev/next; `pillMorph`), paused (opacity .75, no meter). Boards: MediaBar.

**T21 OsdPill** - `Material glass` h 64 r32 pad `0 22 0 10`, gap 14; leading `IconDisc xl 44` (becomes `WaveShape` tertiary/error when off), content slot (`Slider osd` 170 + value `numeralL` tabular min 34 / text / album art + title / workspace waves / battery text + action `Button compact`). Variants: `volume|brightness|muted|micOff|layout|workspace|track|battery`. Width: content-fit with `min`; morphs with `osdMorph`. Boards: OSD.

**T22 LoginCard** - Panel glass w 420 r32 pad `26 28 24`: `WaveAvatar 96`, `titleXl` name, `bodyS` locked-since, `PasswordField`, fingerprint hint (`LoadingWave`-ring pulse), caps-lock chip (`Pill`-like `tertiaryContainer` h 34 -> chip), message. Used on Lock, Greeter (inline 460 pill form), disk unlock (solid). Boards: Lock, LoginStates, Greeter.

**T23 Toolbar** - Glass pill h 80 r40 pad `0 12 0 14` gap 14 hosting `SegmentedButton l veil`, `Divider` (1 x 36 `veilStrong`), `IconButton l veil`, `Button l veil`, primary wave capture `IconButton` (64, `WaveShape`). Boards: Screenshot toolbar; markup editor tool row (h 52, `IconButton` 44 r14 tool + swatches 28 r14).

**T24 CarouselRow** - Horizontally scrolling row with centred selection and edge fade; `ScrollArea` + `listReflow`. Boards: switcher overflow, greeter user picker, wallpaper shelf (same code).

**T25 WindowFrame** - Floating window chrome: `Material` solid/mica, radius `Shape.panel.s`(28), `windowOutline`, `floatingLarge` shadow, optional title strip. Boards: Settings, markup editor, Calculator (app). Used inside `FloatingWindow` (Settings). Note: the compositor draws no radius for floating windows; the window must be a layer or the rounded clip must be done in QML with a transparent window and a compositor `rounding` rule.

**T26 OverviewRibbon** - Workspace row: label column (wave badge 56 `numeralM`/`numeralL`, name `titleDisplay` 22, count `caption`) + strip of `PreviewTile`s + active plate (`veil` @ .08 r32, bleed right). Boards: Overview.

---
## 5. Surfaces (task 4, summary)

Each surface has a full tree in `docs/design/surfaces/<name>.md`. This table
is the index. "Role" is the motion role pair from 3.9.

| Surface | Host | Material | Role in / out | Replaces (`shell/triton/`) | Detail |
|---|---|---|---|---|---|
| Bar (+ indicators, workspace/tray popovers) | layer top, exclusive when pinned | glass islands / mica strip | `islandReveal` / `islandHide` | `bar/*` (7 files) | `surfaces/bar.md` |
| MediaBar (pill + popover) | inside Bar | glass | `pillMorph`, `popoverOpen` | none (new) | `surfaces/media.md` |
| Launcher | layer overlay, focus | thick | `launcherOpen` / `surfaceExit` | `launcher/*` | `surfaces/launcher.md` |
| QuickSettings | layer top-right | glass | `surfaceEnter` / `surfaceExit`, `drill` | `quicksettings/*` | `surfaces/quick-settings.md` |
| Notifications (toasts + centre) | layer top-right | glass | `toastEnter/Exit`, `surfaceEnter` | `notifications/*` | `surfaces/notifications.md` |
| OSD | layer bottom, click-through | glass | `osdEnter` / `osdExit`, `osdMorph` | `osd/*` | `surfaces/osd.md` |
| Lock | session-lock | blurred wallpaper + glass | `surfaceEnterSlow` | `lock/*` | `surfaces/session.md` |
| Greeter | separate greetd instance | same | `surfaceEnterSlow` | `greeter/Greeter.qml` | `surfaces/session.md` |
| Power | layer overlay, focus | scrim + glass pill group | `surfaceEnterSlow`, `pillMorph` | `power/*` | `surfaces/power.md` |
| Overview | layer overlay | backdrop + ribbons | `surfaceEnterSlow` | `overview/*` | `surfaces/overview.md` |
| WindowSwitcher | layer overlay, focus | thick | `surfaceEnter`, `selection` | `windowswitcher/WindowSwitcher.qml` | `surfaces/window-switcher.md` |
| Clipboard | layer overlay, focus | thick | `surfaceEnter`, `listReflow` | `clipboard/*` | `surfaces/clipboard.md` |
| Wallpaper picker | layer bottom dock + top card | thick + glass | `surfaceEnter`, `crossfade` | `wallpaper/*` | `surfaces/wallpaper.md` |
| Screenshot (capture, states, markup) | layer overlay per output | glass chrome | `surfaceEnter`, `selection` | `screenshot/ScreenshotUI.qml` | `surfaces/screenshot.md` |
| Settings app + 14 pages | `FloatingWindow` | mica sidebar + solid | `surfaceEnter`, `drill` | `settings/*` (21 files) | `surfaces/settings.md` |
| Desktop (wallpaper layer) | layer background | none | `crossfade` | `Desktop.qml`, `wallpaper/WallpaperScene.qml` | in `surfaces/wallpaper.md` |

### Surface contract

A surface directory `surfaces/<name>/` contains:
- `<Name>.qml`: the composition (components only, no literals).
- `<Name>Host.qml`: the `SurfaceWindow` + bindings to state/service singletons
  (the only file in the directory that imports `services/`).
- `parts/*.qml` (optional): surface-local components (e.g. the bar's
  `WorkspacePill`). Same rules as everything else: composed from primitives and
  patterns only, no literals, no service imports. If a second surface needs one,
  promote it to `primitives/` or `patterns/`.
- `states/*.qml`: named states for the visual-diff harness (each board state).

State singletons (`LauncherState`, `QuickSettingsState`, ...) stay: they are
`open`, `toggle()`, `dismiss()` and are used by IPC. `Presence` is created in
the Host from `State.open`.

---

## 6. Directory layout

```
shell/triton/
  shell.qml                 entry: fonts, per-screen Variants of Host files only
  qmldir                    (kept)
  tokens/                   GENERATED, never edited
    Theme.qml Palette.qml Type.qml Space.qml Size.qml Shape.qml
    Elevation.qml Motion.qml Icons.qml qmldir
  foundations/              ThemeScope AppText Icon Material StateLayer FocusRing
                            Presence PresenceTransform SpringValue SpringBehavior
                            CornerShape Shadow WaveShape qmldir
  primitives/               Button SplitButton IconButton Fab SegmentedButton Chip
                            ChipGroup Pill Tag Badge Keycap Switch Checkbox Radio
                            Slider ProgressBar ProgressRing LoadingWave TextField
                            SearchField PasswordField Avatar Swatch IconDisc
                            ListRow ListGroup Card SectionHeader Divider Tooltip
                            ScrollArea Tabs NavItem PreviewTile LevelMeter qmldir
  patterns/                 SurfaceWindow Panel Popover Modal Dialog Menu MenuItem
                            MenuSeparator Island StatusPill Toast ChecklistToast
                            NotificationCard NotificationGroup Dock SidebarNav
                            TileGrid Tile EmptyState KeyHintBar SettingRow
                            SettingsPage PlayerCard MediaPill OsdPill LoginCard
                            Toolbar CarouselRow WindowFrame OverviewRibbon qmldir
  surfaces/
    bar/ media/ launcher/ quicksettings/ notifications/ osd/ lock/ greeter/
    power/ overview/ windowswitcher/ clipboard/ wallpaper/ screenshot/
    settings/ (SettingsApp.qml, pages/*.qml) desktop/
  services/                 kept; additions: MediaService (Mpris), AudioService,
                            BrightnessService, WindowSwitcherState,
                            ScreenshotState, UserService, OsdProducers
  fonts/
  dev/
    gallery/                component gallery (every primitive x state x mode)
    states/                 one QML per surface state, named like the board
design/
  tokens.json               extended (3.11)
  boards/                   committed board PNGs (today they live in /tmp/boardout)
scripts/
  generate-theme.py         extended: all tokens/ singletons, --check
  lint-literals.py          R1 enforcement
  compare-board.sh          render state -> PNG -> pixel diff vs design/boards
docs/design/
  component-system.md  surfaces/*.md
```

Layering rule (enforced by lint, imports): `tokens` <- `foundations` <-
`primitives` <- `patterns` <- `surfaces`; `services` is imported only by
`surfaces/*Host.qml` and `shell.qml`. No upward or sideways imports.

Existing files that survive unchanged or nearly: `services/*` (all),
`Icons.qml` (generated), `fonts/`, `shell.qml` structure, `Desktop.qml` window
setup, `LockWindow` lifetime rule (the lock exists for the shell's lifetime).
Everything under `components/` is replaced (see per-component notes: `TritonX`
-> primitive of the same concept). `devshell-*.qml` and `intertest.qml(.bak)`
move to `dev/` or are deleted.

---

## 7. Build order

The graph: tokens -> foundations -> primitives -> patterns -> surface. The
list below is the order that unblocks the most surfaces first and keeps
every step shippable behind a flag.

**Step 0. Generator, lint, gallery (unblocks everything).**
- Fix `generate-theme.py` veil bug; emit all singletons and per-scheme
  `Palette`s; `--check`.
- `lint-literals.py` (start warn-only on legacy dirs, hard-fail on new dirs).
- `dev/gallery/` page that renders each component in a grid of states, in
  dark, light and reduce-motion, plus `Materials` and `Type` board
  re-creations. Commit `design/boards/*.png`.
- Gate: gallery of tokens (type ramp, colour pairs, materials, shadows, shapes)
  matches `Type`, `Color`, `Materials` boards pixel for pixel in dark; in light
  it is reviewed by eye.

**Step 1. Foundations.** `ThemeScope`, `AppText`, `Icon`, `CornerShape`,
`Shadow`, `Material`, `StateLayer`, `FocusRing`, `SpringValue/Behavior`,
`Presence`, `WaveShape`, `SurfaceWindow`.
- Gate: motion page overlays each spring's step response on the curves from
  `Type.dc.html`; `SurfaceWindow` demo opens/closes with enter/exit and
  click-through mask.

**Step 2. Primitive set A.** `Button, IconButton, Chip, Pill, Tag, Badge,
Keycap, Divider, IconDisc, Avatar, Slider, ProgressBar, ProgressRing, Switch,
ListRow, ListGroup, Card, SectionHeader, ScrollArea, Tooltip, LevelMeter`.
- Gate: Controls + Containers + ComponentIndex boards re-created in the
  gallery.

**Step 3. First surfaces: OSD, then Bar.**
- OSD is the smallest surface and exercises `Presence`, `Slider(osd)`,
  `WaveShape`, `OsdPill`, `SurfaceWindow`, `osdMorph`.
- Bar exercises `Island`, `StatusPill`, `IconButton slot`, workspace pill morph,
  the three modes + exclusive zone, popovers (needs `Popover`, `PreviewTile`).
  MediaPill follows once `MediaService` exists.

**Step 4. Primitive set B + panel patterns.** `SegmentedButton, SearchField,
TextField, PasswordField, Checkbox, Radio, Tabs, NavItem, PreviewTile,
LoadingWave, SplitButton`, patterns `Panel, Popover, Modal, Dialog, Menu,
Toast, KeyHintBar, EmptyState, TileGrid/Tile, CarouselRow, NotificationCard/
Group, LoginCard, Toolbar, Dock`.

**Step 5. Panel surfaces, in this order:** Launcher (SearchField, Chip,
ListRow, KeyHintBar, top-hit Card), QuickSettings (TileGrid, Slider, `drill`),
Notifications (cards, groups, toasts), Power (SegmentedButton power variant,
Dialog, ProgressRing), Clipboard (Panel, ListRow selected, EmptyState,
ProgressRing, Dialog), WindowSwitcher + Overview (PreviewTile, CarouselRow,
OverviewRibbon), Wallpaper (Dock, Swatch, PreviewTile), Lock + Greeter
(LoginCard, WaveAvatar, blurred backdrop), Screenshot (Toolbar, SegmentedButton,
Pill, KeyHintBar, markup editor).

**Step 6. Settings app.** `WindowFrame, SidebarNav, SettingsPage, SettingRow,
Swatch`, then pages in the order Appearance (largest, exercises accent,
material cards, stops slider), Bar & Shell, Windows, Displays, Keyboard,
Network, Bluetooth, Sound, Mouse, Power, Notifications, Apps, Users, About.
Narrow mode and search state last.

**Parallelism.** After Step 1, primitive groups and surfaces that do not share
a primitive can proceed independently (e.g. Bar + OSD vs Settings pages).
Foundations and tokens are the only serial dependency.

### Surface definition of done (screenshot comparison against the board)

For each surface state named in its doc:
1. Render `dev/states/<surface>/<state>.qml` headless (Quickshell inside
   `Dockerfile.shelltest`, or the harness `scripts/test-shell.sh`) at the
   board logical size (1646 x 1029, scale 1.75 => 2880 x 1800 device).
2. Diff against `design/boards/<board>.png` cropped to the state's element
   (`scripts/compare-board.sh` produces side-by-side + overlay + a numeric
   score). Layout must match within 2 px for fixed-size parts; text may differ
   in rasterisation.
3. Render again at 1366 x 768, 1920 x 1080, 2560 x 1440 and in light mode and
   with reduce motion. These have no board; the check is "no overflow, no
   overlap, no clipped text, contrast >= 4.5:1 for body text".
4. `lint-literals.py` reports zero in the surface directory.
5. Enter/exit recorded as a 12-frame strip to confirm the role (not pop).

---
## 8. What happens to the existing code

| Existing | Fate |
|---|---|
| `Theme.qml`, `Icons.qml` | Replaced by generated `tokens/`. `Icons` generation unchanged. Keep `applyUserTokens()` behaviour but make it rebuild the whole `Palette` (materials, veils, shadows) |
| `components/TritonText` | -> `AppText` (family/weight enums become role names) |
| `components/TritonIcon` | -> `Icon` (size token instead of `size: real = 22`) |
| `components/IconButton` | -> `IconButton` (add variants, toggle morph, state layer) |
| `components/TritonButton` | -> `Button` (variants now include veil/glass/danger; press morph) |
| `components/TritonChip` | -> `Chip` |
| `components/TritonSwitch`, `TritonSlider` | -> `Switch`, `Slider` (stops, variants, keyboard) |
| `components/WaveShape`, `WavyRing` | -> `WaveShape`, `ProgressRing`, `LoadingWave` |
| `components/RoundedRect` | -> `CornerShape` |
| `components/ContentRow` | dropped; `RowLayout` with centred alignment in patterns |
| `components/DevTestWindow` | -> `dev/` |
| `services/*` | Kept as is. Additions: `MediaService` (Quickshell.Services.Mpris), `AudioService` and `BrightnessService` (extracted from `QsWindow`'s inline Pipewire/brightnessctl code and `shell.qml`'s OSD producer `Connections`), `WindowSwitcherState`, `ScreenshotState`, `UserService` (greeter/lock user list). OSD producers move out of `shell.qml` into `services/OsdProducers.qml` |
| Visual files in `bar/ launcher/ quicksettings/ notifications/ osd/ lock/ greeter/ power/ overview/ windowswitcher/ clipboard/ wallpaper/ screenshot/ settings/` | Replaced by surface compositions. Logic worth lifting is listed per surface in `surfaces/*.md` (key handling, filtering, scoring, grouping, countdown timers, PAM flow) |
| `shell.qml` | Stays thin; each surface becomes one `Variants`/singleton line on its Host |
| `Desktop.qml` | Stays; wallpaper `Image` gets `crossfade` between two images |
| `settings/SettingsWindow.qml` hosted in `FloatingWindow` 1100 x 760 with `minimumSize` 900 x 620 | Window stays, but contents fill and use the narrow layout below 860; initial size is a token (`Size.panel.settings.pref`) |

Counts: Foundations 20 (+ `SurfaceWindow` in patterns), Primitives 34,
Patterns 26, Surfaces 16 including the desktop layer (+ 14 Settings pages), Motion roles 25 + 5 loops +
15 timers.

---

## 9. Contradictions and open questions (task 6)

Q numbers are referenced earlier in this document.

### Decided (2026-11-27). These override the proposals below and in `surfaces/`

- **Q2, light mode:** lock, greeter, power, overview and screenshot are always
  dark. Everything else follows light/dark.
- **Q3, blur:** blur every translucent surface. Compositor blur for shell
  layers, QML blur where the compositor can't reach (session lock). Per-material
  saturation and brightness differences from niri are not a goal.
- **Springs:** own spring component, tested on Quickshell 0.3.0, tuned by eye.
- **Q4, shapes:** three named panel sizes (28/32/36); the "on" Quick Settings
  tile is a rounded square.
- **Bar defaults:** follow `BarStates`: hidden by default with edge reveal,
  120 ms reveal delay.
- **Density:** this is a desktop shell, not a touch one. Deflate the bar and
  other chrome; the boards' sizes, including the 56 px pinned bar, are too big.
  Sizes live in tokens so the compact scale is set in one place. This overrides
  board pixel sizes in this document and in `surfaces/`.

**Q1. QS tile on-state shape.** `QuickSettings.dc.html`: on tile keeps radius 36
(pill) and is `primary`. `Main.dc.html` `.tile.on`: radius 20 + primary (shape
morph). `Type` board says state changes shape (toggle round -> square) and
`Controls` has `tog-off r28`, `tog-on r16`. Component API has
`Tile.onShape: "square"|"pill"`; default proposed `square` (r20), matching
the stated shape rule. Confirm.

**Q2. Light scheme.** (a) Light hexes are hand-picked and unverified
(`tokens.json` note). (b) No surface is shown in light. (c) Missing: light
highlight, light shadow alpha, light `critical` card, light `success`, light
`veilStrong`/`hairline`/`outlineOnGlass` (proposed values in 3.2). (d) The
boards for Lock, Greeter, Power, Overview, Screenshot and the Wallpaper dock are
all dark with white text over a dimmed wallpaper. Proposed: those surfaces
always use the dark palette (`ThemeScope scheme: "dark"`). The Wallpaper board
itself says "Paper is a light image ... Mica and Glass flip to light tints", so
Bar/Panels do follow, although the
panel drawn next to that sentence is itself still dark. Also: `WallpaperStates` says the *scheme follows the
picture*; `Settings` has Dark/Light/Auto. How do the two interact?

**Q3. Blur capabilities.** Boards are specified with niri `background-effect`
(per-surface blur, xray, no per-material saturation outside CSS). The ISO runs
Hyprland with a single blur rule per layer namespace and `no_anim` on layers.
Saturate 1.4-1.5 and brightness .8-.85 cannot be per-material. Options: accept
the difference; bake brightness into fill; use a per-namespace `xray` rule;
implement real blur in QML (`MultiEffect` + `ShaderEffectSource`) for the few
full-screen surfaces (Lock 10 px, Greeter 12, Overview 14, Power 18), as
`docs/audit.md` defect 14 already suggests. Decision needed on Mica `xray`
(Hyprland xray per layer rule) and per-class namespaces.

**Q4. Radius and chip shape.** Panel radii: 28 (menus, toast, dialog,
Main QS), 32 (QS board, media popover, login card, wallpaper colours card), 36
(clipboard, switcher, wallpaper dock). 36 is not in `tokens.json`. Chip: `.t-chip`
10 (36 h); Controls chips are 32 h r16 buttons; Clipboard chips 36 h r18;
Wallpaper source chips 40 h r20 (with `primary` selection). Connected group:
`components.css` ends 22 inner 8 gap 3; Controls ends 20 inner 6 gap 2.
Proposal: three panel tiers (28/32/36) kept as `Shape.panel.{s,m,l}`; chips
two shapes `square 10` / `round`; connected values from `components.css`.

**Q5. Bar timing and defaults.** Reveal dwell is 120 ms (BarStates), "Reveal
delay 150 ms" default (Settings board slider), and 300 ms in code
(`shell`/`revealDelay` default). Settings board shows Autohide as default
("Autohide, default"), but the code default and `docs/audit.md` call "pinned"
the default. Pinned card says "Takes 32 px" while BarStates pinned strip and
`Size.bar` are 56 px. Reveal slider scale (150 ms at 25 % position?) is
unspecified.

**Q6. Display type weights and roles.** Jost is 600 in `tokens.json`, 500 for
Settings page titles (40), QS title (22), media popover title (24), switcher
header (28), launcher calc; 600 for notification centre (30) and dialog
titles. QS panel title is Jost 500 22 while `Type` Title L is Flex 600 20 (QS
title in `Type` board sample uses "Quick settings" in Jost 600 40 for Headline
L). Proposal: `titleDisplay` is 500, `headlineL/M` are 600; Settings page title
uses `headlineL` at 500 override or becomes 600. Confirm.

**Q7. State-layer and small-control details.** Controls board `.hov` is 10 %
and `.prs` 14 % (on-primary), tokens say 8/10. Menu hover tint:
`rgb(176 198 255 / .16)` (Containers) vs `rgb(178 203 213 / .16)` (Materials).
Switch on-thumb position `(22, 2)` (components.css) vs `(23, 4)` (Controls). QS
sliders: 52 px pill (Main) vs 44 px `.sld` (QuickSettings board) vs OSD 16 px.
Which is the QS slider?

**Q8. Button size ladder.** Boards use 30, 32, 34, 36, 38, 40, 44, 48, 52,
56, 60, 62, 64, 68, 72 for interactive heights. Ladder in `tokens.json`: 32 /
40 / 48 / 56. Proposal adds a 36 step (`Button` size `compact`; `Size.h.chip`) for notification buttons, OSD Saver and chips.
All others snap to the ladder as listed in 3.4. Any exceptions wanted?

**Q9. Type details.** Fractional sizes (11.5, 12.5, 13.5, 14.5) snapped.
Label tracking: `label_s` +14 %, `.t-nav-label` +.12 em, `.t-eyebrow` 13 px +.14 em,
`.lbl` .12 or .14, Settings uses 14 px sentence-case primary headers (no caps).
ComponentIndex says "Section label: Eyebrow caps, 13/.14em". Proposal: keep
`labelS` (12) and `eyebrow` (13) and `sectionTitle` (14) as three roles with
the documented use of each.

**Q10. Ambient animation.** No board gives durations for the loading morph,
fingerprint pulse, wavy progress phase drift, waiting bar. Values in 3.9 are
placeholders. Also `shake` damping and distance are not tokenised.

**Q11. Icon size binding.** No table says which icon size goes with which
control. Proposed in 4.2 (button s 18, m 20, l/xl 24; ibtn s 18, m 20, slot/l 22-24; nav 22; list disc 22; chip 18; bar 22).

**Q12. Spring token provenance.** `tokens.json` says "Spring values are from
memory of M3 Expressive"; README says "cross-checked against community ports
of the Compose tokens, not the official token page". The Type board curves
"were not redrawn for the new stiffness". Verify against Material's token
tables before locking the generator (cheap: the numbers are data). Also:
QML's `SpringAnimation` is not stiffness/damping-ratio; the spec requires
the `SpringValue` implementation or fitted easing (3.9).

**Q13. Floating window rounding.** Boards: floating windows radius 28 with
outline and shadow, done by the compositor (niri rule `floating_window 28`).
Hyprland `rounding` applies per window rules; the Settings `FloatingWindow`
needs either a Hyprland rule (`rounding = 28` for class
`callisto-settings`, which `docs/audit.md` says is currently not matched) or
a transparent QML window with a clipped rounded content and QML shadow.

**Q14. Settings pages without boards.** The sidebar lists 14 pages; boards
draw Appearance, Displays, Bar & Shell, Windows, Keyboard (+ Network via the
QS hand-off). Bluetooth, Sound, Mouse & touchpad, Power, Notifications, Apps,
Users, About have no board; they are composed from `SettingRow`/`ListGroup`
and need a design pass. Existing panels (`BluetoothPanel`, `SoundPanel` ...)
give the content.

**Q15. Narrow breakpoint and window size.** Settings: "Below 860 px the sidebar
becomes a full-width list and each page slides in over it" (board). Floating
window default 1100 x 760 while the Hyprland session scales by 1.75. Does a
window of 860 mean logical px? (assumed). Settings sidebar width 280 vs 200 in the
QS hand-off mock (different window size; treated as responsive).

**Q16. Mica fallback and adaptive mica needs inputs.** "Mica falls back to
solid on battery saver or when a window loses focus for long" and the
luminance trigger need a battery-saver signal (power-profiles-daemon
`power-saver`) and a luminance value from the engine. Neither exists in the
shell today.

**Q17. Greeter runs as a different user/process.** It cannot read
`~/.config/callisto/tokens.json`; the greeter needs the system default token
file and the shared `tokens/` + `foundations/` + `primitives/` modules (an
import path outside the user's shell). Packaging question.

**Q18. Media pill vs "never forces the bar open".** MediaBar rule: with
autohide the pill does not reveal the bar; but the pill lives in a bar island.
When hidden, is there any media affordance (OSD only)? Board says media keys
show the OSD. Assumed yes.

**Q19. Bell dot ring colour.** `#3a3c41` (glass) vs `#2a2c31` (mica) are
approximations of the effective surface colour. `Badge.ringTone` takes the
material's opaque equivalent; for translucent materials this is an
approximation. Accepted unless told otherwise.

**Q20. Notification centre and lock hidden content.** Lock shows "N
notifications - content hidden"; board also lists rows (Mia / Message). The
Settings key `lockscreenNotifications` exists. Both states needed: list of
sender+app only (default) vs hidden count only. Confirm which is which.

**Q21. Super+V.** The Clipboard board opens on Super+V. The Settings
Keyboard board lists "Toggle floating: Super+V" and "Close window: Super+Q, also
used by Open launcher" (an intentional conflict demo). `configs/hypr/hyprland.lua`
binds Super+V to the clipboard, Super+F to float and Super+Q to close.
Settings board and the Hyprland config disagree on float; the Overview board
hints say Super+Tab cycles workspaces while the switcher is Alt+Tab. Confirm the
canonical keymap; the Keyboard page reads it from the store, not from boards.

---

## Appendix A. Board literal -> token snap table (generator test data)

(Selected; the generator carries the full table so the lint can show a
"nearest token" hint.)

| Literal | Token | Delta |
|---|---|---|
| 11.5, 11 px text | `micro` 11 | -0.5 / 0 |
| 12.5 px text (mono, subtitle) | `monoS` 12 / `bodyS` 13 | -0.5 / +0.5 |
| 13.5 px text | `labelM` 13 / `labelL` 14 | -0.5 / +0.5 |
| 14.5 px text | `bodyM` 15 | +0.5 |
| 17 px Jost | `numeralM` 18 | +1 |
| 19 px Jost | `numeralM` 18 | -1 |
| 20 px Jost (wallpaper colours) | `titleDisplay` 24 | +4 (review) |
| 22 px Jost | `titleDisplay` 24 | +2 |
| 30 px Jost | `headlineM` 28 | -2 |
| 32 px Jost | `titleXl` 34 | +2 |
| 38 px Jost (greeter brand) | `headlineL` 40 | +2 |
| 18 px / 36 px radius pills | `Shape.pill(h)` | exact |
| rows h 56 / 58 / 60 / 62 | `Size.h.xl` (56) or `row` (64) by role | review |
| h 34 / 30 / 38 | 36 / 32 / 40 | +2 |
| scrim .25 / .32 | `scrimSoft` .30 | +.05 / -.02 |
| white-alpha .06 | `veilFaint` | exact |
| white-alpha .08 / .09 / .10 / .12 | `veil` | -.02 .. +.02 |
| white-alpha .14 / .16 / .18 | `veilHi` (.16) | -.02 .. +.02 |
| white-alpha .20 / .22 / .26 / .28 | `veilStrong` (.22) | -.02 .. +.06 |
| white-alpha .30 / .35 | `outlineOnGlass` (.30) | +.05 |
| text opacity .75 / .8 / .85 | `emphasisMed` .80 | -.05 .. +.05 |
| text opacity .6 / .65 / .7 | `emphasisLow` .65 | -.05 .. +.05 |
