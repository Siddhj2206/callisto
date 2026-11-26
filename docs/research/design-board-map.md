# Triton design-board map — spec extraction

Source of truth: `references/*.dc.html` (extracted design boards) + `references/triton/tokens.css` + `references/triton/components.css` + `design/tokens.json`. All values are **logical px at 1.75× scale** (physical display 2880×1800, logical 1646×1029). Every number below is quoted exactly as written in the boards — no rounding.

The boards embed a shared stylesheet (`triton:begin`…`triton:end`) identical in every file: it is `tokens.css` + `components.css` verbatim. Class prefix `t-`. Boards additionally define a handful of one-off classes, noted per-surface.

---

## 1. Shared primitives inventory

### 1.1 Materials (the four surfaces)

| Material | Fill (dark) | Backdrop filter | Extras | Use |
|---|---|---|---|---|
| Solid | `surface_container_low` #191C20 … `-highest` #33353A, alpha 1 | none | — | content: text, code, lists, media |
| Mica | `rgb(25 28 32 / .72)` | `blur(48px) saturate(1.4) brightness(.8)` | niri `xray true` (samples wallpaper only, never recomputes) | chrome: pinned bar, sidebars, terminal backgrounds |
| Glass | `rgb(40 42 47 / .70)` | `blur(32px) saturate(1.5) brightness(.85)` | `inset 0 1px 0 rgb(255 255 255 / .14)` highlight + shadow `0 16px 40px rgb(0 0 0 / .45)` | floating things: bar islands, menus, OSD, quick settings |
| Thick Glass | `rgb(40 42 47 / .88)` | `blur(40px) saturate(1.4) brightness(.8)` | same highlight + shadow `0 30px 80px rgb(0 0 0 / .55)` | launcher, big modal panels over busy content |

- **Veil** (fill for controls sitting on Glass/scrim — a solid container there "reads as a hole"): `--t-veil` `rgb(255 255 255 / .10)`, `--t-veil-hi` `rgb(255 255 255 / .16)`. Light scheme: `rgb(25 28 32 / .06)` and `/ .10`.
- **Adaptive Mica**: when mean wallpaper luminance under bar > 0.6, add .08 alpha (dark) / .06 (light).
- Light scheme glass/mica values differ: mica `rgb(243 243 250 / .78)`, glass `rgb(231 232 238 / .82)`, thick `/ .90`; brightness 1.05, never dim; primary is fills-only in light.
- Scrims: dialogs `rgb(0 0 0 / .45)`; clipboard/switcher panels `rgb(0 0 0 / .35)`; launcher `rgb(0 0 0 / .3)`; quicksettings demo `rgb(0 0 0 / .25)`.
- Rules: no glass on glass; text under 4.5:1 → solid; Mica falls back to solid on battery saver.
- Window frames: tiled = radius 0, gaps 0. Floating = radius 28, `overflow:hidden`, `box-shadow: 0 0 0 1px rgb(255 255 255 / .12), 0 30px 80px rgb(0 0 0 / .55)`.

### 1.2 Color tokens (dark scheme — the default; all shell surfaces are dark)

Roles: primary `#B0C6FF` / on `#002D6E`; primary-container `#00429B` / on `#D9E2FF`; secondary `#BFC6DC`, secondary-container `#3F4759` / on `#DBE2F9`; tertiary `#FFB59B` / on `#5A1B00`, tertiary-container `#7C3114` / on `#FFDBCE`; error `#FFB4AB` / on `#690005`, error-container `#93000A` / on `#FFDAD6`; surface `#111318`; tiers `#0C0E13` lowest, `#191C20` low, `#1D2024` container, `#282A2F` high, `#33353A` highest; on-surface `#E2E2E9`; on-surface-variant `#C4C6D0`; outline `#8E9099`; outline-variant `#44474F`; signals `#FFC857` warn, `#6FE0F5` info (8px LED dots only, never fills). State layers: hover 8%, focus 10%, press 10%, drag 16%; disabled content 38%, disabled container 12% (both over `#E2E2E9`).

### 1.3 Shape scale

Radius tokens: xs 8, sm 12, md 16, lg 20, xl 28, full 9999 (50%). List rows: outer 24, inner 6. Connected groups: ends 22 (24 in `l` size), inner 8, gap 3 (2 in one-off controls boards). The **wave**: 9-lobed SVG path, viewBox `0 0 100 100`, full path in `design/tokens.json` `shape.wave.path`. Wave is identity only: launcher button, avatars, album art, swatches, loading, OSD "off" state icon container. State changes shape: toggled control goes round → rounded square; selected workspace dot → wider pill; press tightens corners to 12.

### 1.4 Buttons — `.t-btn` family

| Class | H | Radius | Padding | Font |
|---|---|---|---|---|
| `.t-btn` (filled) | 40 | 20 | 0 24px | 600 14px Google Sans Flex, gap 8 |
| `.t-btn.s` | 32 | 16 | 0 16px | 13px |
| `.t-btn.l` | 48 | 24 | 0 28px | 16px |
| `.t-btn.xl` | 56 | 28 | 0 32px | 17px |

Variants: `tonal` (secondary-container #3F4759 / #DBE2F9), `outlined` (transparent, 1px inset outline #8E9099, primary text), `text` (transparent, padding 0 14px), `veil` (on glass: veil fill, on-surface text), `t-glass` (glass fill — greeter session/layout pickers). Press: radius tightens to 12. Disabled: bg `rgb(226 226 233 / .12)`, text `/ .38`. Note: Notifications board uses locally-scoped smaller buttons: 36px h / radius 18 / font 13px 600.

### 1.5 Icon buttons — `.t-ibtn` family

| Size | W×H | Radius |
|---|---|---|
| default | 40×40 | 20 |
| `.l` | 48×48 | 24 |
| `.s` | 32×32 | 16 |

Variants: standard (transparent, icon on-surface-variant), `filled` (primary/on-primary), `tonal` (secondary-container), `outlined` (1px inset outline), `neutral` (surface-container-highest — unselected toggle), `veil` (on glass). Toggle state `.toggled` squares corners: 20→12 (default), 24→14 (`.l`). Bar uses a bespoke 44×44 radius-22 bell/ibtn.

### 1.6 Connected groups — `.t-seg`

Container flex, gap 3. Children: flex 1, height 44 (`.l`: 48), padding 0 20px, font 600 14px (`.l`: 15px), icon 20px, bg surface-container-high (or veil in `.veil` variant), radius 8; first child `22px 8px 8px 22px` (`.l`: 24px ends), last mirrored. `.on` child: primary bg, on-primary text. Used: screenshot toolbar (`.t-seg l veil`), power menu (custom large), settings (`.sld` variant with stops).

### 1.7 Switch — `.t-switch`

Track 52×32, radius 16, bg surface-container-highest, border 2px outline. Off thumb: 16×16 r8 at left 6/top 6, fill outline. On: track primary; thumb 24×24 r12 at left 22/top 2, fill on-primary, may contain `check` icon 16px colored primary. (Controls board shows a slightly different on-thumb position left 23/top 4 — minor discrepancy, see §5.)

### 1.8 Sliders

Canonical `.t-slider`: height 44; active track `.a` left, top 14, height 16, radius `8px 2px 2px 8px`, primary; inactive `.b` right, radius `2px 8px 8px 2px`, surface-container-highest; handle `.h` 4×44 r2 primary, `margin-left:-2px`. Variant with stops `.sld .d`: 4×4 dots at top 20 (on-primary on active side, primary on inactive). Controls board sizes: M 44 (with icon inside active track, icon padded-left 14), S 28, range slider 16, centered 28. QuickSettings/Main use inline pill-sliders: track height 52, radius 26, bg `rgb(255 255 255 / .12)`, active part full-height rounded `26px 4px 4px 26px` containing the leading icon; handle 4×60 protruding ±4px. OSD track: height 16, radius 8, active `8px 3px 3px 8px`, handle 4px wide protruding ±5px.

### 1.9 Chips, pills, tags, kbd, eyebrow

| Primitive | H | Radius | Font | Fill |
|---|---|---|---|---|
| `.t-chip` (filter chip) | 36 | 10 | 500 14px, icon 18 | outlined 1px outline; `.on` secondary-container fill, no outline |
| `.t-pill` (floating label, non-interactive) | 36 | 18 | 600 14px, icon 18, gap 8, padding 0 14px 0 10px | glass |
| `.t-tag` | auto (padding 3px 10px) | 10 | 600 12px +.04em | tertiary-container #7C3114 / #FFDBCE |
| `.t-kbd` | 24, min-width 24 | 7 | 600 12px JetBrains Mono | transparent, inset 1px `rgb(255 255 255 / .35)` |
| `.t-eyebrow` | — | — | 600 13px +.14em uppercase | primary |
| section label `.lbl` | — | — | 600 12px +.12/.14em uppercase | on-surface-variant |

Clipboard uses ad-hoc round chips: h36 r18 padding 0 16 font 500 13.5, selected = secondary-container, unselected = inset 1px white/30.

### 1.10 Lists — `.t-list` / `.t-li` / `.t-ic`

Column, gap 2. Row: min-height 64, padding 12px 20px, gap 16, bg surface-container; radius 6 inner, `24px 24px 6px 6px` first, `6px 6px 24px 24px` last, 24px all when only child. `.t` title 500 16px; `.s` supporting 13px on-surface-variant, margin-top 1px. `.t-ic` icon disc: 40×40 r20, secondary-container bg/on-color, icon 22px. `.t-li.on` selected: secondary-container bg + on-secondary-container text; `.s` inherits at opacity .8. Rows sit one tone above background (on `.t-card`, rows use surface-container-high).

Clipboard rows differ: min-height 60, padding 8px 16px 8px 12px, gap 14, radius 14 (selected 28), icon disc 38×38 r19, title 500 14.5, subtitle 12px.

### 1.11 Nav — `.t-nav` / `.t-nav-label`

`.t-nav`: h48, r24, gap 16, padding 0 16px, font 500 15px on-surface, icon 22px on-surface-variant. `.on`: primary-container bg, on-primary-container text, weight 600. `.t-nav-label`: 600 12px +.12em uppercase, on-surface-variant opacity .8, padding 18px 16px 6px.

### 1.12 Search field — `.t-field` / inline variants

Canonical `.t-field`: h52 r26, bg `rgb(255 255 255 / .1)`, gap 12, padding 0 18px. Launcher search row: height 72, icon disc is a 40px wave in primary with search icon in on-primary color; query font 500 24px. Clipboard: h52 r26 bg white/12, padding 0 18px, trailing hint text 12.5px. Controls board search: h52 r26 bg surface-container-highest, leading search icon + trailing mic, text 16px. Lock/Greeter password field: h52–60 r26–30, focused ring `inset 0 0 0 2px primary`, go-button 40–46px circle primary with `arrow_forward`.

### 1.13 FAB

From Controls: S 40×40 r12 icon 20; M 56×56 r16 icon 24; L 96×96 r28 icon 36; extended h56 r16 padding `0 22px 0 18px` icon+label 600 16px. Fill: primary-container #00429B / #D9E2FF, shadow `0 6px 16px rgb(0 0 0 / .45)`.

### 1.14 Menus, dialogs, toasts, tooltips

- Context menu: Glass, radius 28, width ~250–310, padding 10, items `.mi` h44 r22 padding 0 14px gap 12 font 500 15px; hover bg `rgb(176 198 255 / .16)`; separator 1px `rgb(255 255 255 / .14)`, margin 6px 14px. Danger item colored error.
- Toast: Glass, h56 r28, padding `0 10px 0 24px`, gap 22, font 500 15px, trailing text-button action; bottom center, 4 s.
- Dialog: Thick Glass over 45% scrim, radius 28, width 464, padding `28px 28px 22px`; title Jost 30px 600 with 56px wave+icon leading; destructive confirm button filled error-container #93000A/#FFDAD6.
- Tooltip: h32 r12, padding 0 12px, 500 13px, glass-ish `rgb(40 42 47 / .85)` + highlight + small shadow.
- Notification card radius: `24px 24px 24px 10px` (toast) / `24px 24px 24px 8px` (in-center) / `20px 20px 20px 8px` stacked collapsed.

### 1.15 Badge, avatar, icon defaults

Dot badge: 10×10 r5 tertiary #FFB59B, 2px ring of surrounding bg color. Count badge: min-w20 h20 r10, tertiary bg, text 700 12px #5A1B00, ring 2px. Wave avatar: 40/48/56/96/150px wave shapes with initials in Jost (e.g. 17px at 48px, 34px at 96px). Material Symbols: default 24px at FILL 0, wght 500, GRAD 0, opsz 24; `.f` for FILL 1.

### 1.16 Wavy progress

Linear: amplitude ~3px, wavelength 24px, stroke-width 4 round-cap primary #B0C6FF; remainder flat grey line (secondary-container #3F4759 or white/.25). Played part wavy, rest flat. Circular: 9-lobe wavy ring; used for countdowns (Clipboard sensitive items: 34px ring, mono 11px number inside) and loading. Loading morph: wave → squircle (r9 rotated 30°) → disc.

### 1.17 Misc

- Scrollbar: rest width 4px thumb r2 `rgb(226 226 233 / .5)`; hover width 10 r5 `/ .75`; auto-hides.
- Divider: 1px outline-variant #44474F, may fade to transparent at list ends.
- Key caps `.kc` (shortcut rows in settings): min-w30 h30 r8 padding 0 9px, 500 13px mono, bg surface-container-high, inset bottom shadow `0 -2px 0 rgb(0 0 0 / .35)`. (Note: panels use the lighter `.t-kbd`/`.kb u` variant instead.)
- Focus ring: `2px solid on-surface` offset 2px (controls); primary 2–3px rings on selections.
- Springs `[stiffness damping]`: spatial fast 800/0.6 (~9% overshoot — toggles, workspace pill, press morphs); spatial 380/0.8 (panels, menus, resize); spatial slow 200/0.8 (overview, lock); effects fast 3800/1.0 (hover/press state layers); effects 1600/1.0 (color/icon-fill/text); effects slow 800/1.0 (wallpaper crossfade, palette swap). Reduce motion: 120 ms fades.

---

## 2. Per-surface spec tables

### 2.1 Bar (BarStates + Main + MediaBar)

**Geometry.** Island: h56, radius full (28), padding 0 6px, internal gap 4, positioned `top:8px`, `left/right:16px` when floating. Pinned state: full-width strip h56, edge-to-edge, square, Mica, windows start below it. Hidden state: nothing reserved; invisible 2px top-edge strip wakes it.

**Left island contents (in order):** launcher button — 44×44 wave (fill primary #B0C6FF) with `apps` icon 22px in on-primary #002D6E centered at 11px inset; 8px spacer; workspaces `.ws`: h40 min-width 40 r20, font Jost 600 17px, on-surface-variant; `.on` min-width 56, primary bg/on-primary text. With window title: divider 1×28 `rgb(255 255 255 / .2)` margin `0 10px 0 8px`, app icon 22px filled primary, app name 600 15px, document title 14px onv (margin 0 16px 0 6px), fades at edge.

**Right island contents:** clock `.clk` — time Jost 600 26px letter-spacing -.2px, date 500 14px onv, gap 12, padding `0 16px 0 18px` (Main uses `0 18px 0 20px`); status pill `.stat` h44 r22 padding 0 18px gap 16, bg primary-container #00429B, color #D9E2FF, icons 22px-ish + battery percent text 600; bell button 44×44 r22 bg veil, notifications icon, optional unread dot 10px tertiary ringed `#3a3c41` (glass) or `#2a2c31` (mica).

**Media pill (center island, MediaBar):** exists only while playing; h56 r28 centered `left:50%; transform:translateX(-50%)`, padding 0 8px, gap 10. Contents: album art 40px wave clip, title max-width 200px truncated (13.5px 600 / artist 12px at 75% opacity), live level meter 3 bars (w3 h7–16 r2 primary), transport buttons 40×40 r20 — skip prev/next transparent, play/pause filled primary disc. Paused: opacity .75, no meter, fades out after 2 min, play button only. Click → popover.

**Media popover:** Glass, w440 r32 padding 22. Art 112px wave. Title Jost 500 24px, artist·album 14px/80%, source 12.5px/60%. Wavy progress 396-wide + mono 12px times. Controls row: shuffle/repeat icons at .7 opacity, skip buttons 40px, central 64×64 wave play/pause button (icon 28px on-primary). Volume slider row. Player-picker variant: rows h68 padding `0 14px 0 10px` gap 14, first/last radii `28px 28px 8px 8px` / `8px 8px 28px 28px`, middle 8; selected row solid primary with on-primary text, unselected white/.06.

**Indicator variants (BarStates 5):** Recording — extra pill h44 r22 padding `0 16px 0 12px` gap 8 bg error-container #93000A/#FFDAD6, `fiber_manual_record` 20px filled, label "Recording 00:42", inner stop button 30×30 r10 white/18. Mic in use — same pill shape in tertiary-container with app name. DND — bell filled secondary-container, `notifications_off` filled icon. Charging — bolt icon filled tertiary inline before percent. Low battery — whole `.stat` becomes error-container with `battery_alert`. Offline — `.stat` becomes tertiary-container with `wifi_off`.

**Behavior:** reveal on 120 ms top-edge dwell or Super+B or window-needs-attention (workspace pulses); hide 600 ms after pointer leaves, never while popover open or notification expanded; fullscreen suppresses, 300 ms dwell reveals. Floating = Glass, pinned/docked = Mica. Popovers (workspace preview w440 r28 padding `14px 16px 16px` with 150×150 r14 thumbs; tray overflow w292 r28 padding 16, grid 3 cols gap `10px 8px`, entries 56×56 r20 veil discs + 12px 500 labels) keep bar revealed.

### 2.2 Launcher

Panel: Thick Glass, radius 28, width 900 (main) / 572 (calc, commands), over 30% black scrim; centered in real use. Search row h72 padding `0 16px 0 14px` gap 14: leading 40px wave+icon badge (wave fill varies: primary for apps, primary for calc, tertiary #FFB59B for commands), query 500 24px with 2×26 primary caret; filter `.t-chip`s trailing (All/Apps/Files/Windows or tertiary-tinted "Commands"). Divider 1px `rgb(255 255 255 / .12)`.

Results area padding 14: **top hit** card w310 r24 bg primary-container/on-primary-container padding 20, gap 14 — label eyebrow at .85, 96px circle app icon (bg primary, icon 44px filled on-primary), name Jost 600 40px ls -.6px, subtitle 14px at .85, actions row `.t-btn` + `.t-btn veil`. **Result rows**: h56 r20 padding `0 12px 0 8px` gap 14; `.t-ic` 40px disc (app-specific tint: tertiary/secondary-container/highest), title 500 16px + subtitle 13px onv; workspace tag `.e` 600 12px r10 padding `3px 8px` secondary-container. Group labels `.lbl` 600 12px +.14em uppercase onv padding `12px 12px 6px`. Selected row: secondary-container bg. Footer h52 padding 0 20px gap 22: kbd hints (↑↓ move, Enter open, Tab actions, Alt+Enter reveal, Esc close). Calc state: result 64px Jost display with copy/open actions. Prefixes: `>` commands, `=` math, `/` files. Opens from bar wave on spatial default; results update in place.

### 2.3 OSD

Pill: Glass, h64 r32, padding `0 22px 0 10px`, gap 14, bottom-center 48px above screen edge. Standard width 330 (fixed demo width). Icon container `.ico` 44×44 r22 white/12 — becomes **wave shape in tertiary/error-container** when state is off/muted. Track `.trk` w170 h16 r8 white/18, active primary radius `8px 3px 3px 8px`, handle 4px wide protruding ±5px. Value: Jost 600 26px tabular, min-width 34 right-aligned. Variants: volume (icon steps volume_off→up), muted (wave tertiary `volume_off`, "Muted" 15px), brightness (`brightness_6`, sun fills), mic off (error-container wave `mic_off`, text 600 16px, stays until dismissed — w270), keyboard layout (Jost 600 24px "DE" + 12px language), workspace (3 waves, center 42px primary with Jost number, sides 30px highest-fill; only for keyboard switching), track change (w346, 44px wave album art, title 600 15 + artist 12, `skip_next` filled primary trailing), battery low (w346, error wave `battery_alert`, "Battery 15%" + time-left, trailing 34px "Saver" pill button h34 r17 padding 0 14px primary; stays 6s — the only OSD with an action). Timing: enter spatial fast, hold 1.2 s (key-hold refreshes), exit effects default. One at a time — new morphs old in place. Never takes focus, pointer events pass through.

### 2.4 Notifications

**Toasts**: top-right below bar zone, width 400, column gap 10. Card `.nc`: Glass, padding `14px 16px 14px 14px`, radius `24px 24px 24px 10px`, gap 14. Structure: leading 48px wave avatar (tertiary-container fill, Jost initials 18px) or `.t-ic` 48px disc; header row name 600 16px + time 12px onv; body 14px onv. Actions: inline reply field h36 r18 white/12 + send button 36×36 primary circle (icon 18); or small buttons h36 r18 600 13px (`.pf` primary filled, `.pt` tonal white/14, `.pe` error-container, `.pg` green `#8CD6A0`/`#00391B` for accept-call). Overflow: "2 more" pill h36 r18 padding 0 16 icon `stacks` 18px. Max 4 visible; hover pauses; slide-in spatial default; timeout 6 s.

**Notification center**: Glass panel w440, radius 28, padding `18px 16px`, right-anchored, full height minus 20px margins. Header: "Notifications" Jost 600 30px + DND toggle button h36 tonal with `dark_mode` 18px. Groups: header row `.grp` padding `10px 6px 8px` gap 10 — 32px app disc, name 600 15, count 12px onv, expand chevron, "Clear" 600 13px primary. Items `.pn`: bg white/.09, radius `20px 20px 20px 8px`, padding `12px 14px`, name 600 15 + preview 13px onv + trailing time 12px. Collapsed groups show stacked peek (offset 12px inset card at 50% opacity, main card height 62 area). "Show 1 more" 600 13px primary.

**Card types**: Standard (icon, timeout 6s), Message (wave contact, inline reply), Critical (error-container glass `rgb(147 0 10 / .78)` blur 32 — stays until dismissed, ignores DND; buttons inverted #FFDAD6/#410002), Progress (wavy bar + % + Pause/Cancel text-buttons h30), Call (56px wave avatar, Jost 22px name, split Decline/Accept h40 flex-1), Screenshot (88×60 r12 thumbnail + Open/Show in Files). DND sends toasts straight to center; critical+calls still arrive. Lock screen shows sender+app only.

### 2.5 Quick Settings

Panel: Glass, width 400, radius 32 (this board; Main demo uses r28), padding 20. Header: title Jost 500 22px, trailing 44×44 veil ibtn (settings gear). Tile grid: 2 cols, gap 8; tiles h72, radius 36 in this board — off tiles: r36 white/12 bg; on tiles: **primary bg, on-primary text, radius stays 36** here (in Main demo, `.tile` off = r36 white/.1, `.tile.on` = r20 primary — shape morph!). Layout inside: padding `0 10px 0 12px`, gap 12, icon 24px, label 600 14px + subtitle 12px at .8; trailing `chevron_right` 22px when drillable. Sliders: rows gap 6 margin-top 18, leading icon 24px, `.sld` 44px slider with stops dots. Bottom row margin-top 18 gap 8: "All settings" pill h48 r24 primary-container/on-primary-container 600 14px flex 1 + power button 48×48 r24 white/12.

**Drill-in (Wi-Fi page)**: same 400px panel; header back ibtn + title + master `.t-switch`. Network list: rows h60 padding 0 14px gap 14, bg white/.09, connected radii `22px 22px 6px 6px` first / 6 middle / `6px 6px 22px 22px` last; leading wifi-strength icon (filled primary when connected), name 600 14 + status 12px/.75, trailing `check_circle` 20px filled primary or `lock` 18px/.7. Footer: "All network settings" h48 r24 primary-container pill. Hand-off: deep opens floating Settings window (sidebar Mica 200px + content solid; sidebar `.t-nav` items, content lists `.t-list/.t-li`). Nothing leaves the panel; Back returns.

Main demo quick settings also shows: header battery line (`82% · 6 h 10 min left`, 14px 500 onv) + 3 trailing 40px veil ibtns (tune/lock/power — power in tertiary-container), 6 tiles 2-col grid, sliders as full-height 52px pill variant, and media card: white/.1 bg r24 padding 16, 56px wave art with center hole disc, "Now playing" eyebrow 11px, title Jost 600 19px, artist 13px onv, prev/next ibtns, play button 56×48 r16 primary, wavy progress with times 12px tabular.

### 2.6 Lock / Greeter / Login states

**Lock**: wallpaper blurred `blur(10px) brightness(.72) saturate(1.1)` + `rgb(0 10 30 / .2)` tint. Top center: date 26px 500, clock Jost **250px** 600 ls -10px lh .92. Calendar pill: h44 r22 padding `0 20px 0 14px` glass, `event` 22px primary. Notifications bottom-left w380: hidden-content label + `.nc` glass rows radius 24 padding `12px 18px 12px 12px` gap 14 (app disc 40, name 600 15, generic type 13 onv). **Login card**: glass w420 r32 padding `26px 28px 24px` centered low — 96px wave avatar with initials Jost 34px, name Jost 600 34px, "Locked …" 13px onv, password field h56 r28 white/12 + focus ring `inset 0 0 0 2px primary` padding `0 8px 0 18px` gap 12: lock icon, dots font 22px ls .3em, visibility eye, go-button 44×44 r22 primary `arrow_forward`. Fingerprint hint 13px onv with 20px icon. Media pill bottom-right w360 h64 r32 padding 0 12 gap 12: 40px wave art, title/artist, pause button 44×44 r14 primary. Status pill bottom-right h56 r28 padding 0 22 gap 20: wifi icon, battery+percent, layout "US" mono 13px.

**Greeter**: blur(12) brightness(.62). Brand top-left: 56px logo wave+orbit ring, "triton" Jost 600 38px. Clock top-right Jost 44px + date 15px. User picker: side users 96px waves (label 500 14px onv below), selected 150px wave with 1.8px primary stroke ring scaled 1.12, "Other…" dashed `rgb(255 255 255 / .5)` 2.6px dasharray 6 6 circle-plus. Selected name Jost 54px centered. Password pill w460 h60 r30 white/12 + primary ring. Session+layout pickers: `.t-btn t-glass` with leading icon 20px and trailing `arrow_drop_down`. Bottom-left wifi pill h56 r28; bottom-right three 56×56 r28 glass circles (accessibility_new, restart_alt, power — power in `rgb(124 49 20 / .8)`). Footer mono 12px.

**Login states** (field states): idle — quiet field, disabled go-button `rgb(226 226 233 / .12)` bg / `.38` fg; typing — primary ring, go fills primary, eye reveals 5 s; wrong — field shakes once, clears, bg `rgb(147 0 10 / .72)`, ring 2px `#FFB4AB`, error message 13px 600 `#FFDAD6` with `error` icon; fingerprint — 104px double wave rings pulsing (`B0C6FF` at .25/.5 opacity) + filled fingerprint 44px; caps lock — tertiary-container chip h34 r17 with `keyboard_capslock`; unlocking — wave→squircle→disc loading morph + "Unlocking" Jost 26px; session picker — glass menu w260 r28 padding 10, `.mi` rows with check on current; disk passphrase — solid no-blur dark gradient, key icon, same field.

### 2.7 Power / PowerStates

**Power menu**: full-screen over blurred wallpaper `blur(18px) brightness(.5) saturate(1.1)` + `rgb(0 10 30 / .25)`. Greeting centered top ~270: Jost 600 64px ls -1.2px + uptime 17px/.85. Connected group centered: 5 segments — each `.btn` 140×140 r14 column gap 10, icon 44px, label 600 15px; group radii ends `70px 14px 14px 70px` … `14px 14px 70px 70px`; gap 6. Colors: Lock primary-container, Sleep/Log out secondary-container, Restart tertiary-container, Shut down **focused = expanded pill** w300 r70 horizontal gap 16, tertiary bg #FFB59B/#5A1B00, icon filled 52px, label Jost 32px + "Press Enter" 13px, shadow `0 14px 40px rgb(0 0 0 / .45)`. Unsaved warning pill: glass h48 r24 padding `0 22px 0 14px`, warning icon filled tertiary. Kbd hints row: ←→ move, Enter confirm, 1–5 jump, Esc cancel. Footer mono 12px "neptuno · triton 0.1".

**PowerStates** (compact 96px variant in 2×2 demo cells): buttons 96×96 r12 gap 6 icon 32 label 600 13; focused `.x` = 210px wide r48 horizontal, icon 36, name Jost 24 + "Press Enter" 12px. Opens focused on Lock (safest first). Focused action grows and gains label; glass note h40 r20 when outcome changes ("3 updates install on restart"). Countdown: 132px wavy ring draining (tertiary stroke on white/.3 track), Jost 64px number, 5 s, any key/click cancels; lock and sleep skip. Unsaved-work dialog: thick glass w520 r28 padding `22px 24px 18px`, warning icon 32px tertiary, title Jost 26, app rows h44 r16 white/.08 padding 0 12 gap 12, actions Cancel(text)/Review(tonal)/Shut down anyway(tertiary filled).

### 2.8 Screenshot / Capture states

Capture UI: dim `rgb(0 0 0 / .5)` everywhere except selection (screen mode: 16% dim). Selection: 2px primary border, rule-of-thirds lines 1px white/.22, corner handles `.hd` + edge handles `.he` 26×8 / 8×26. Size chip: glass h36 r18 mono 500 14px `crop` icon 18 primary. Hint pill top-center: glass h48 r24 padding 0 24 gap 22 kbd hints (Drag select, Space window, Enter capture, Esc cancel). **Toolbar**: glass h80 r40 bottom-center padding `0 12px 0 14px` gap 14 — `.t-seg l veil` (Region/Window/Screen, icons `screenshot_region`/`select_window`/`desktop_windows`), 1×36 divider white/.2, then `ads_click` pointer ibtn-l veil, timer `.t-btn l veil` ("Off" + timer icon), `videocam` ibtn-l veil; capture = 64×64 wave button primary + `photo_camera` 28px on-primary. Footer text 13px with shadow. Window mode: hovered window gets primary tint overlay `rgb(176 198 255 / .16)` + 2px outline + floating name pill `.t-pill`. Screen mode: 4px inset primary border, monitor chip `eDP-1 · 2880 × 1800` mono. Record mode: wave turns red (#FFB4AB + `fiber_manual_record`), audio pills row (`mic`, `speaker`, `ads_click` — `.t-pill` glass). Countdown: 200px red wave with Jost 120px number + Esc hint. After capture: preview card bottom-left w340 glass r28 padding `12px 12px 14px` — thumbnail h170 r18, name 600 15 + mono dims, "Copied" chip, buttons Edit (filled, flex 1) + folder_open/delete veil ibtns, self-dismiss progress bar h4 r2 62%/primary over 5 s. Markup editor: floating glass window w700, tools row h52 — `.tool` 44×44 r14 (pan_tool_alt, edit, ink_highlighter, arrow_right_alt, rectangle, title, blur_on, crop; `.on` = secondary-container), divider, swatches 28×28 r14, undo/redo veil ibtns, actions Discard(text)/Copy(tonal)/Save(filled). Saves to Pictures/Screenshots + copies; Shift = copy only. Private windows blacked out (Alt includes).

### 2.9 Clipboard / ClipboardStates

Panel: Thick Glass, centered, w1000 h780 radius **36**, padding 22, over 35% scrim; two columns: list w430 + preview. Search field h52 r26 white/12 padding 0 18 with trailing "Super+V" hint 12.5px/.7. Filter chips row (h36 r18, ad-hoc round chips — not `.t-chip` square 10): All (selected = #3F4759/#DBE2F9), Text/Images/Links/Code/Pinned (inset 1px white/30). Sections: eyebrow 12px +.12em uppercase .75 padding `12px 12px 6px` ("Pinned", "Today"). Rows: min-h60, padding `8px 16px 8px 12px`, gap 14, radius 14 (selected 28), unselected white/.06, selected solid primary with on-primary text and disc bg `rgb(0 45 110 / .15)`; leading disc 38×38 r19 white/12 with type icon 20px; title 500 14.5 truncated (mono 13.5 for code), meta 12px/.75. Pinned rows show `push_pin` 18px trailing. Sensitive rows: masked dots, countdown wavy ring 34px (mono 11px seconds inside). Empty state: 88px wave at white/16 + Jost 22px + explainer 14px/.8. Clear-history dialog: solid (no glass on glass) + scrim, destructive confirm. Settings rows: keep-history seg pills (1 h / 24 h / 7 d), switches for sensitive-ignore and keep-images. Behavior: Super+V, closes on paste, hover/arrows move preview, sensitive items masked/memory-only/wiped 30 s or after one paste, Shift+Enter plain-text paste, links paste URL, reduce motion = 120 ms fade.

### 2.10 Window switcher / states

Panel: Thick Glass centered, w1212 radius 36, padding `24px 24px 20px`, over 35% scrim. Header: focused-window title Jost 500 28px + meta 13.5px/.8 ("Work · workspace 2 · Console · 2nd most recent"), trailing "2 of 5" 13px/.8. Card row: gap 16, cards 220 wide padding 10 radius 24 — unselected white/.06 flat; **selected: primary-container #00429B bg + `inset 0 0 0 3px #B0C6FF` ring + shadow `0 10px 30px rgb(0 0 0 / .4)` + scale(1.04)**. Card contents: thumbnail 200×124 r14 with inset 1px white/.1; below, app disc 32×32 r16 (white/14 or primary when selected) with icon 18px filled + title 600 13.5 truncated max-w 130 + workspace 12px/.75. Attention dot: 14×14 r7 tertiary with 4px `rgb(255 181 155 / .3)` halo. "Floating" tag: `.t-tag` overridden bg black/.55 white text. Kbd hints footer: Tab next, ⇧Tab back, Q close, F float, Esc cancel. Opens after 120 ms hold — quick tap swaps with last window invisibly.

States: overflow — row scrolls, selection stays centered; same-app cycling Super+` — filters to one app; compact mode (9+ windows or setting) — icon tiles 32px discs in a row, circle → rounded-square shape morph for selection, one preview above; private windows — preview hidden/blurred, `visibility_off` badge, Alt reveals; type-to-find — search field appears, rows become list `title — app` format.

### 2.11 Overview (bonus, skimmed)

Full-screen blurred `blur(14px) brightness(.5) saturate(1.1)`. Workspace ribbons: horizontal strips of window thumbnails r16 shadow `0 10px 30px rgb(0 0 0 / .4)`; active ribbon plate white/.08 rounded 32 (bleeds off right edge). Workspace labels left edge: 56px wave numbered badge (primary when active, highest otherwise), name Jost 22px, count 12px. Window name labels: `.t-pill` glass floating at thumbnail corner. Focused window: ring `0 0 0 3px primary` + halo `0 0 0 6px rgb(176 198 255 / .25)` + shadow. Top-center search pill w524 h56 r28 glass, leading 36px wave. Bottom-center hints pill h52 r26 glass.

### 2.12 Main desktop (composed reference)

Windows: tiled Mica, focused column outlined `2px solid primary` inset -2. Files app sidebar w272 padding `80px 12px 0`; nav rows h48 r24 padding 0 18 gap 14 (`.nav.on` secondary-container). Files header h72 padding 0 16: back ibtn, path pill h44 r22 white/.1 padding 0 18, view toggle connected pair 48×44 (`22px`/`8px 22px 22px 8px` radii). File rows h60 r20 padding `0 14px 0 10px` gap 14: icon tile 40×40 **r12** (note: not the `.t-ic` circle — app content), name 500 16, meta column w84 right-aligned 14px onv; selected row secondary-container. Extended FAB h56 r16 primary-container padding `0 24px 0 20px` gap 12 shadow `0 6px 18px rgb(0 0 0 / .4)`. Terminal: Mica, mono 14/24, prompt primary, output tertiary accents. Calculator floating glass w360 r28 padding `12px 16px 16px`: display Jost 500 64px; keys h60 r30 white/.1 font Jost 24, `.op` r18 secondary-container, `.eq` r18 primary, `.fn` primary text.

---

## 3. Icon usage map

All Material Symbols ligatures used in markup are **present** in `design/fonts/symbols.codepoints` — nothing missing. Main.dc.html additionally uses inline stroke SVGs (wifi, bt, moon, sun, leaf, contrast, vol, tune, lock, power, bell, batt, back, search, list, grid, folder, file, code, plus, prev, next, play, close, apps, star, clock, trash, home) — these predate the icon migration and map to ligatures listed below.

| Icon | Boards |
|---|---|
| accessibility_new | Greeter |
| add, edit, grid_view, view_list, home, search, folder, star, mail, notifications, settings, dark_mode, mic, lock, wifi, check, close, arrow_drop_down | Controls |
| apps, wifi, volume_up, battery_5_bar, battery_alert, notifications, notifications_off, fiber_manual_record, stop, mic, bolt, wifi_off, more_horiz, cloud_done, vpn_key, system_update, folder | BarStates |
| wifi, volume_up, battery_5_bar, notifications, apps, skip_previous, skip_next, pause, play_arrow, shuffle, repeat | MediaBar |
| search, calculate, chevron_right, terminal, contacts, settings_remote, description, dark_mode, palette, wallpaper, content_copy | Launcher |
| volume_up, volume_off, brightness_6, mic_off, keyboard, skip_next, battery_alert | OSD |
| chat, folder_copy, send, dark_mode, event, expand_less, expand_more, system_update, mail, battery_alert, download, call, call_end, stacks | Notifications |
| settings, wifi, bluetooth, volume_up, bedtime, chevron_right, light_mode, tune, power_settings_new, arrow_back, network_wifi_3_bar/2/1, check_circle, lock, open_in_new, palette, lan, vpn_key | QuickSettings |
| folder_open, open_in_new, content_copy, edit, edit_note, terminal, more_horiz, delete, chevron_right, folder, code, dark_mode, wifi, expand_more, chat | Containers |
| lock, bedtime, logout, restart_alt, power_settings_new, warning, system_update, terminal, edit_note | Power/PowerStates |
| crop, ads_click, timer, videocam, screenshot_region, select_window, desktop_windows, photo_camera, fiber_manual_record, mic, speaker, check, edit, folder_open, delete, undo, redo, pan_tool_alt, ink_highlighter, arrow_right_alt, rectangle, title, blur_on | Screenshot/ScreenshotStates |
| search, terminal, push_pin, image, palette, notes, link, folder, key, content_paste, file_copy, history, delete_sweep, visibility_off | Clipboard/ClipboardStates |
| alt_route, folder, terminal, public, chat, code, visibility_off, search, draw, music_note, mail, photo_library | WindowSwitcher/States |
| lock, visibility, visibility_off, arrow_forward, fingerprint, event, chat, system_update, pause, wifi, battery_5_bar | Lock |
| lock, arrow_forward, desktop_windows, keyboard, arrow_drop_down, wifi, accessibility_new, restart_alt, power_settings_new | Greeter |
| lock, arrow_forward, visibility, fingerprint, error, keyboard_capslock, check, terminal, key | LoginStates |
| chat, mail, edit_note, folder, terminal, language, music_note, movie | Overview |
| add_photo_alternate, colors, rocket_launch, schedule, photo_library, info, visibility, check | Wallpaper/States |
| add, apps, animation, battery_full, battery_saver, bluetooth, blur_on, brightness_auto, check, check_circle, contrast, info, keyboard, laptop_mac, light_mode, monitor, mouse, person, progress_activity, shapes, toolbar, tv, web_asset, volume_up, wifi, notifications, search, open_in_new, palette | Settings/States |

Icons in the codepoints file not seen in board markup (kept for runtime-driven states): battery_0–6_bar variants, battery_charging_full, bluetooth_connected/disabled, brightness_high/low/medium, done, headphones, headset_mic, lightbulb, nightlight, radio_button_checked, screen_record, signal_wifi_off, sync, volume_down/mute, wb_sunny, wifi_lock. Dynamic battery/wifi-level icons are runtime-driven, so the full families are needed even though boards only show some.

---

## 4. Type scale table

Family tokens: display **Jost**, UI **Google Sans Flex**, mono **JetBrains Mono**, icons **Material Symbols Rounded** (FILL 0/1, wght 500, GRAD 0, opsz 24).

| Style | Family | Size/line | Weight | Color | Where |
|---|---|---|---|---|---|
| Display XL (lock clock) | Jost | 250/.92 | 600 ls -10px | white | Lock |
| Board titles (doc only) | Jost | 88/1 ls -3px · 72/1 ls -2.4px | 600 | on-surface | board headers (not shell) |
| Display | Jost | 64/64 ls -1px | 600 | — | calc result, power greeting, countdown numbers |
| Greeter name | Jost | 54/1 ls -1px | 600 | white | Greeter |
| Headline L | Jost | 40/44 ls -.6px | 600 | — | files folder title, launcher top-hit name |
| Headline M | Jost | 28/32 | 600 | — | panel titles, switcher header, notifications center |
| Clock (bar) | Jost | 26/~1 ls -.2px | 600 | on-surface | bar clock, OSD values |
| Dialog/greeter-brand | Jost | 38/30/24 various | 600 | — | dialogs, OSD kbd-layout, media popover title |
| Title L | Flex | 20/26 | 600 | — | QS panel title (22px 500 in board — see §5) |
| Title M | Flex | 16/22 | 600 | — | list titles, notification names |
| Body L | Flex | 16/22 | 400/500 | — | rows, result entries |
| Body M (UI default) | Flex | 15/21 | 400/500 | — | everything |
| Body S | Flex | 13/18 | 400 | on-surface-variant mostly | subtitles, meta |
| Label L | Flex | 14/20 | 600 | — | buttons, chips, tile labels |
| Label S stencil | Flex | 12/16 +.14em uppercase | 600 | onv or primary | eyebrows, section labels, "Now playing" |
| Mono | JetBrains Mono | 14/24 | 400 | — | terminal, code, hex |
| Mono small | JetBrains Mono | 12–13.5 | 400–600 | onv | timestamps, kbd caps, dimensions, footer |
| Launcher query | Flex | 24 | 500 | — | search input |
| Password dots | Flex | 22 ls .3em | — | — | lock field |
| QS tile title/sub | Flex | 14/12 | 600/400(.8) | inherits tile | quick settings tiles |
| Clipboard row title/meta | Flex | 14.5/12 | 500/400(.75) | — | clipboard rows |
| Switcher card title | Flex | 13.5 | 600 | — | switcher cards |
| Media pill title/artist | Flex | 13.5/12 | 600/400(.75) | — | bar media pill |

Rule from Type board: emphasis steps weight 400→600, never italic; numerals in Jost; targets ≥ 40px logical.

---

## 5. Discrepancies / open questions

1. **Quick settings tile shape morph**: QuickSettings.dc.html `.on` tiles keep radius 36 (same as off); Main.dc.html `.tile.on` morphs to radius 20. Type board says toggle = round→square, so Main is presumably canonical — but the dedicated QS board doesn't do it. Confirm intent.
2. **Quick settings panel radius**: 32 in QuickSettings.dc.html vs 28 in Main.dc.html. Media popover also uses 32. Which is canonical for panel overlays?
3. **Switch on-thumb position**: components.css `.t-switch.on>i` at `left:22px;top:2px`; Controls board inline version `left:23px;top:4px`. Off by a pixel or two; pick the CSS file.
4. **Icon sizes are not uniform within the same control class**: `.t-ibtn` default icon ~20–22px in practice; bar uses 22, notifications use 18–24, switcher discs 18, list `.t-ic` 22. The tokens define icon sizes 18/20/24/28 but no binding to control sizes. Needs a decision.
5. **Clipboard/switcher/panel radius 36** — not in the shape scale (max 28 + full). These are the only 36px-radius surfaces (also QS tile radius 36 = half-height pill, which is fine). Is 36 a sanctioned "panel" radius or should it be 28/32?
6. **Clipboard filter chips are round pills (r18)** while `.t-chip` spec is radius 10; Launcher uses proper `.t-chip` r10. Inconsistent chip shapes between Launcher and Clipboard.
7. **Notification action buttons are a local size** (h36 r18 13px) not in the `.t-btn` size ladder (32/40/48/56 with r16 at 32). Effectively a new "xs-ish" button. Same for OSD "Saver" button h34 r17.
8. **Workspace pill `.ws.on` width**: tokens/Main show min-width 56; Type-board morph demo shows 40→64. Values differ; 56 appears in real bars.
9. **Fractional px** in media/clipboard text (13.5, 12.5, 14.5) — breaks the integer type scale. Probably casual; decide whether to round.
10. **Light scheme values are hand-picked/unverified** (per tokens.json note); light is never shown on any board. Also all shells are authored dark-only; wallpaper-dim behaviors in light are unspecified.
11. **Bar popover corner radius**: workspace preview uses r28; tray overflow r28 but quick-settings uses r28/32 — mostly consistent at 28 except QS/media at 32.
12. **Adaptive mica trigger** is defined (luminance > .6) but no board shows the state visually.
13. **OSD width**: fixed 330 in most variants, but 270/346/wrap for others — the sizing rule (fit-content vs fixed) isn't stated.
14. **Borders**: floating windows get `0 0 0 1px rgb(255 255 255 / .12)` outline; glass panels don't. Confirm whether layer-shell panels want the same hairline (Glass already has the top highlight inset).
15. Bell unread dot ring color differs by material (`#3a3c41` on glass vs `#2a2c31` on mica) — presumably "match the effective surface color", which with translucency is approximate.
