# Triton Shell Audit

Scope: `shell/triton/**` (all QML), `scripts/engine/callisto-apply`, `scripts/start-callisto`, `configs/hypr/hyprland.conf`. Read in full, 2026-11-26.

Severity: **CRITICAL** (broken behavior) · **HIGH** (perf/correctness risk) · **MEDIUM** (improvement) · **LOW** (polish).

The dominant finding: Triton is currently a skin, not a shell. Nearly every production surface renders beautifully but is fed by hardcoded mocks, and the few service bindings that exist (volume, battery, notifications, wallpaper) are half-wired or buggy. The engine ↔ shell settings contract is broken in both directions (wrong sections, wrong keys, stale accent application). Individually these are small fixes; together they mean almost nothing the user can touch actually works.

---

## CRITICAL

### C1. Wallpaper preview/commit logic is irreversibly broken after one generative commit
**Files:** `wallpaper/WallpaperWindow.qml:54-72`, `wallpaper/WallpaperWindow.qml:74-80`, `Desktop.qml:35,48-55`
Two independent bugs compound:
- `preview()` sets only one of `previewPath`/`previewKind` and never clears the other. `Desktop.qml` checks `previewKind` first, so once a generative wallpaper is previewed, previewing an *image* wallpaper afterwards has no visual effect (the stale `previewKind` still wins).
- `commit()` writes only one of `appearance.wallpaper` / `appearance.wallpaperKind` and never clears the other. After committing any generative wallpaper, `wallpaperKind` is set in the store forever; committing an image wallpaper later writes `wallpaper` but the Loader in Desktop.qml (`activeKind !== "" && !== "image"`) stays active — the image can never come back without hand-editing `settings.json`.
**Fix:** in both `preview()` and `commit()`, always write both channels: clear `previewKind` when previewing an image and vice versa; in `commit()`, `SettingsService.set` both keys (wallpaper path plus `wallpaperKind: "image"` or `""`).

### C2. Launcher has no backend at all — production instance is empty
**File:** `launcher/Launcher.qml:51-61`
The production `LauncherPanel` receives no `query` wiring, no `results`, no `topHit*`, and `onQueryEdited`/`onActivated`/`onChipClicked` are unhandled (only `onClosed`/`onActivated` dismiss). Opening the launcher in production shows a blank panel with no results. There is no app-scanning service; `services/` has no `LauncherService`. Typing edits nothing (query is one-way pushed into the input via the imperative `onQueryChanged` assignment in `LauncherPanel.qml:89`, which also breaks the binding).
**Fix:** write a `LauncherService` (desktop-file scan + file/window index), pass its filtered results into the panel, and let the panel be the single owner of query state (two-way binding, drop `onQueryChanged` imperative assignment).

### C3. Launcher visibility drifts from LauncherState — window can stay visible forever
**File:** `launcher/Launcher.qml:27-37`
`property bool open: LauncherState.open` copies the state once into a non-readonly property; `onOpenChanged` only handles the open direction. When state goes false via any path that isn't `root.dismiss()` (e.g. `qs ipc call launcher toggle` → `LauncherState.toggle()`), the toggle *does* reach `open` through the binding (the binding is live since `open` is assigned once)... but the visible window never hides because only `open → true` sets `visible = true`; nothing ever sets `visible = false` except `root.dismiss()`. Toggling the launcher closed via IPC leaves a fullscreen overlay with `keyboardFocus: Exclusive` — which, since `keyboardFocus` is bound to `visible`, keeps grabbing the keyboard while invisible-ish state. Actually worse: the panel and scrim remain visible and interactive-looking, while LauncherState thinks it's closed; the bar stops force-showing. Net effect: visual/keyboard state drift.
**Fix:** `visible: LauncherState.open` as a plain binding (plus a close animation gate if desired), delete the imperative `onOpenChanged`/`dismiss` split.

### C4. Notification toast expiry is broken — a single shared Timer for all toasts
**File:** `services/NotificationState.qml:56-61,101-106`
One `expireTimer` with one mutable `item` property is restarted for every new non-critical toast. Effect: only the most recently arrived toast ever expires; all earlier non-critical toasts stay on screen forever (until clicked). Also the 6s clock restarts on every new arrival, so a busy stream of notifications pins the latest toast indefinitely.
**Fix:** per-toast expiry (ToastWindow already implements correct per-card timers at `notifications/ToastWindow.qml:62-66` — delete the singleton timer entirely and let the window own expiry, or track expiry timestamps in the model and sweep with one repeating timer).

### C5. NotificationCard's cover-all MouseArea eats action/reply clicks
**File:** `notifications/NotificationCard.qml:282-285`
A root `MouseArea` with `anchors.fill: parent` is declared *after* (on top of) the entire card content — the reply input, send button, and action buttons are all children drawn earlier. In Qt Quick, the topmost MouseArea gets the events; child MouseAreas inside the card never see clicks. Result: reply can never be typed/sent and action buttons can never fire; every click anywhere dismisses the toast (in ToastWindow the card's `onClicked` dismisses). The notification action system is completely dead.
**Fix:** move the click-to-dismiss area *behind* the content (declare it first), or use `z` ordering, or accept clicks only in a dedicated strip. Interactive children must be above the dismiss area.

### C6. Lock screen exists but is never instantiated — `loginctl lock-session` strands the user
**Files:** `shell.qml` (no import/instantiation of `lock/`), `configs/hypr/hyprland.conf:179`
`hyprland.conf` binds `Super+Escape` to `loginctl lock-session`, but no ext-session-lock surface exists anywhere in the shell — `lock/LockScreen.qml` is only shown in `devshell-lock.qml`. There is no session-lock client at all, so locking either does nothing or (with any lock provider absent) leaves the session in an undefined state. The lock screen, the most security-critical surface, is 100% missing wiring. Same class: `windowswitcher/WindowSwitcher.qml` and `screenshot/ScreenshotUI.qml` exist but are never instantiated in `shell.qml` — there is no window switcher and no screenshot UI in the running shell.
**Fix:** implement a session-lock integration (Quickshell's `WlrSessionLock`) hosting LockScreen; create windows/state singletons for WindowSwitcher and ScreenshotUI and IPC/keybinds for them, or delete them until wired.

### C7. Power menu actions do nothing
**File:** `power/PowerWindow.qml:30-35`
`onActionTriggered` closes the menu and `console.log`s the index. Lock/sleep/logout/restart/shutdown are all no-ops. This is the only power UI in the system.
**Fix:** wire to real commands (`loginctl lock-session`, `systemctl suspend`, `loginctl terminate-session`, `systemctl reboot/poweroff`), with a confirmation for the destructive ones.

### C8. Settings store sections mismatch: Mouse/Keyboard/Displays panels write keys the engine never reads
**Files:** `settings/MousePanel.qml:31-42`, `settings/KeyboardPanel.qml:39-40`, `settings/DisplaysPanel.qml:206-207` vs `scripts/engine/callisto-apply:240-264,268-296`
The engine reads `store["input"]` (`naturalScroll`, `tapToClick`, `keyboardLayout`). The panels write to `store["mouse"]` (`mouse.naturalScroll`, `mouse.tapToClick`) and `store["keyboard"]` (`keyboard.repeat`). SettingsService accepts any section, writes succeed, engine ignores them — toggles are pure placebo. Same for `windows.focusFollowsMouse`: that one *is* correct (WindowsPanel writes `windows.*`, engine reads `windows.*` — the one wired pair).
**Fix:** unify the schema in one documented place: panels write `input.naturalScroll`, `input.tapToClick`, `input.repeat`; extend the engine to emit the repeat-rate/delay and keyboard repeat keywords.

### C9. Accent changes apply one generation late (or never)
**Files:** `scripts/engine/callisto-apply:299-305,268-296`
`tokens_primary()` re-reads `~/.config/callisto/tokens.json` **from disk** — but at the time `apply_live()` runs, this file has just been written by the same invocation, so it works only if the write actually happened and `atomic_write` didn't bail. More importantly, `apply_live` reads the token file rather than the freshly-computed `effective` tokens passed everywhere else; if the write is skipped (no-op compare) the hex falls back to `c6c6d0` (gray) whenever tokens.json doesn't exist or is malformed — pushing a gray border on first boot. Design bug: the live push uses a stale-cache read of its own output instead of the in-memory result. Fix: pass `effective` into `apply_live` and use `effective["color"]["dark"]["primary"]`.
**Severity note:** also crashes nothing, but borders get wrong colors silently.

### C10. Every overlay layer surface eats clicks across its whole transparent extent; no click-off-to-dismiss
**Files:** `quicksettings/QsWindow.qml:14-23`, `notifications/CenterWindow.qml:12-20`, `notifications/ToastWindow.qml:15-24`, `osd/OsdWindow.qml` (implicit height strip)
Layer surfaces receive input over their entire window geometry regardless of pixel alpha. QsWindow's window is `(400+16) × (panel height+78)` anchored top-right — mostly transparent — and has no click-off MouseArea at all: clicks beside the panel hit the layer surface and are swallowed (never reach windows below, never dismiss the panel). Same for CenterWindow (440+20 wide, full-height strip — the 20px transparent right margin plus everything outside the panel column eats input along the entire screen edge). ToastWindow's window eats a 424px-wide strip of the top-right corner permanently (window is `visible` whenever ≥1 toast exists, and the strip blocks clicks to windows underneath even beside/below the toasts). OSD at least is non-interactive by design but its strip still eats input (the board says pass-through — unachieved; the MouseArea with `propagateComposedEvents` does not propagate to other windows, only within the scene).
**Fix:** keep windows sized to content, or mask input: quickshell supports `mask: Region`/`inputRegion`-style control — set an input region matching only the opaque panel rect, or restructure so the panel is the full extent of the window. Add click-off dismissal scrims for QS and the center.

### C11. WallpaperWindow grabs exclusive keyboard focus even when hidden
**File:** `wallpaper/WallpaperWindow.qml:24`
`WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` is unconditional (unlike launcher/clipboard/overview which bind to `visible`). The window exists at all times (`visible: WallpaperState.open`), so from shell startup there is an invisible Overlay-layer surface demanding exclusive keyboard focus whenever the compositor considers it. On compositors that honor the request regardless of visibility state transitions this can steal all keyboard input; at minimum it's one accidental visibility flip away from a soft-lock.
**Fix:** `keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None` like the other surfaces.

### C12. IPC toggle for wallpaper previews nothing and can't revert correctly
**File:** `shell.qml:135-138`
`wallpaper toggle` opens the picker with `WallpaperState.show()`, but opening the picker immediately calls `preview()` of the *currently applied* wallpaper (`onVisibleChanged` → `preview()`), which is harmless — however `WallpaperState.open` is never initialized against the store, `applied` in WallpaperWindow is a local `property int` initialized to 0 and never synced to the real applied wallpaper, so the check disc and initial selection are wrong unless the user happens to use Orbit. Also closing with revert after no change still fires a Desktop repaint flash.
**Fix:** derive `applied`/`selected` on open from `SettingsService.get("appearance","wallpaper"/"wallpaperKind")` matched against the wallpaper list.

### C13. Quick settings panel is a static mock in production
**Files:** `quicksettings/QsWindow.qml:33-49`, `quicksettings/QuickSettingsPanel.qml`
Tiles are hardcoded (`Wi-Fi "Not connected"`, all `on: false`), `onTileClicked`/`onDrillIn` for anything but Wi-Fi are unhandled, `wifiNetworks` is empty (drill-in is an empty list), `brightness`/`volume` sliders are panel-local props not bound to Pipewire/backlight and `onBrightnessMoved`/`onVolumeMoved` are unhandled — dragging the volume slider does nothing to the system. The gear button `onGearClicked` is unhandled (dead). The single most-used system surface is entirely decorative.
**Fix:** bind volume/brightness to Pipewire/brightnessctl services the way Bar.qml already does for volume; wire tiles to NetworkManager/BlueZ/power-profiles or hide them until backed; wire `gearClicked` and `tileClicked`.

### C14. OSD is never triggered by anything
**Files:** `configs/hypr/hyprland.conf:167-176`, `shell.qml:100-138`, `services/OsdState.qml`
Media/brightness keys exec `wpctl`/`brightnessctl` directly; nothing calls `OsdState.show()`. There is no `osd` IPC target in shell.qml, and no service observing Pipewire volume changes to produce OSD events. `hyprland.conf`'s comment "the shell's OSD observes these changes" is aspirational — the OSD can literally never appear in production. Additionally `OsdState.show()` uses magic numbers (`v === 7` for BatteryLow) coupled by comment to `Osd.Variant` ordering — fragile across edits.
**Fix:** add an `IpcHandler { target: "osd"; function show(...) }` or better: a Pipewire/UPower observer inside the shell that calls `OsdState.show` on default-sink volume/mute changes, and bind brightness keys to a small helper that also pings the OSD. Move the variant enum into a shared singleton (or pass strings) to kill the magic-number coupling.

### C15. `swaybg` races and duplicates the shell's own wallpaper layer
**Files:** `configs/hypr/hyprland.conf:22`, `shell/triton/Desktop.qml`
Hyprland exec-once starts `swaybg` with a hardcoded `/usr/share/backgrounds/callisto/wallpaper.jpg` while the shell renders its own Background-layer wallpaper surface per screen from the settings store. Two wallpaper renderers stacked: swaybg is hidden wasted memory/GPU in the best case, and flashes through/behind during shell startup, crashes, or transparency glitches in the worst. The comment says "the settings app re-execs it when the wallpaper changes" — no such logic exists anywhere.
**Fix:** delete the swaybg exec-once; Desktop.qml is the wallpaper renderer.

### C16. WallpaperThumb.qml redeclares base property `path` — component fails to load
**File:** `wallpaper/WallpaperThumb.qml:7-9`
`WallpaperScene` already declares `property string path`; `WallpaperThumb` (which *is* a WallpaperScene) redeclares `property string path` — QML rejects redeclaration of an inherited property ("Property value set multiple times" / duplicate property error depending on engine version). At minimum it's a hard error in newer Qt; if it loads by accident it shadows confusingly. Either way the thumbnail strip (`WallpaperDock.qml:152-156`) depends on this type.
**Fix:** delete the redeclaration (the base property is inherited).

### C17. `expanded` group toggling in the notification center is unwired
**Files:** `notifications/NotificationCenter.qml:22,161`, `notifications/CenterWindow.qml:22-31`
The chevron emits `toggleGroup(idx)`; CenterWindow never handles it, and `NotificationState` has no toggle function. Collapsed groups can never be expanded. Also `hiddenCount`/`"Show N more"` is non-interactive dead text.
**Fix:** implement `NotificationState.toggleGroup(idx)` (flip `expanded` on a copied group, like `rebuildGroups` does) and connect it.

---

## HIGH

### H1. Store write race: rapid successive `set()` calls lose data and skip applies
**File:** `services/SettingsService.qml:57-91`
`writeProc` is a single `Process`. If `set()` is called while it's still running (a slider drag emits dozens of writes), `running = true` on an already-running process is ignored in quickshell — the write is silently dropped even though `root.store` was already updated. Worse, `applyProc` is guarded by `if (!applyProc.running)` — so applies during a write burst are skipped and never retried. Net: settings UI can diverge from disk and from the applied system state, silently. Also `writeProc.stdinEnabled` juggling is fragile.
**Fix:** serialize writes: keep a `pendingPayload`/`dirty` flag; on `onExited`, if dirty, write again. After final write completes, always fire apply (debounced ~300ms).

### H2. ContentRow imperative anchor assignment is an anti-pattern and racy
**File:** `components/ContentRow.qml:28-37`
`centerChildren()` imperatively writes `child.anchors.verticalCenter` in a JS loop on `onChildrenChanged`. This clobbers any binding a child author set, fires only on children-changed (not on later reparenting), assigns into an attached property group imperatively (the exact pattern the QML docs warn against), and — since everything inside is inside a `Row` positioner — vertical anchoring of positioner children is meaningless/conflicting in the first place (Row owns `y` positioning of its children! Actually anchors *do* apply within Row for the cross axis only if the Row doesn't set y — Qt Rows DO center children by their own logic only when `layoutDirection`… in practice Row positions y=0 unless child has its own anchor; the imperative assignment is what makes it work, which means this component is a hack around positioner behavior). It "works" but is fragile, invisible to readers, and breaks silently when children are Loaders or positions.
**Fix:** use a proper vertical centering contract: either set `Row`'s children via delegates that self-center, or use `anchors.verticalCenter` declaratively in children, or implement the row as an `Item` + manual `Row` inside with `anchors.verticalCenter` on a wrapper. At minimum document that ContentRow clobbers anchor bindings.

### H3. Bell/notification `time` is the literal string "now" forever
**File:** `services/NotificationState.qml:43`
`time: "now"` is baked at insertion and never updated — the center shows "now" for hours-old notifications. Needs a timestamp and a periodically-refreshed relative-time binding, or insertion-time wallclock formatted once.

### H4. Notification history is unbounded; center has no scrolling and fixed window height
**Files:** `services/NotificationState.qml:50-84`, `notifications/NotificationCenter.qml`, `notifications/CenterWindow.qml:22-27`
Groups/items arrays grow forever (no cap, no eviction) — memory and a Repeater-per-item cost that grows without bound in a session. Meanwhile `NotificationCenter` height is externally pinned (`height: parent.height - 40`) while its content is a plain unscrollable `Column` — once content exceeds the window, lower groups are simply clipped away with no scroll view. `clip: true` hides the overflow.
**Fix:** cap history per group (with real `hiddenCount` accounting) and total; wrap the groups column in a `Flickable`/`ListView` with proper delegate reuse.

### H5. Fullscreen overlays never unload; invisible surfaces keep rendering cost
**Files:** `launcher/Launcher.qml`, `clipboard/ClipboardWindow.qml`, `overview/OverviewWindow.qml`, `power/PowerWindow.qml`
All overlay windows are constructed at startup and merely visibility-flipped — intentional per the comment — but their entire scene graphs (including `clip: true` rectangles, Shape paths, Repeaters) stay live. Combined with `layerrule = blur on` on the `quickshell` namespace, each visible overlay forces blur passes over large regions on a possibly-llvmpipe system. At minimum the heavy panels (clipboard 1000×780, overview fullscreen with mock thumbnails) should be inside Loaders activated by state. Also `blur` on *all* quickshell surfaces including the fullscreen wallpaper/desktop layer is pointless GPU burn — the desktop layer is opaque and needs no blur behind it.
**Fix:** gate panel content in `Loader { active: State.open }`; scope the blur layerrule to panel-ish namespaces (set explicit namespaces per surface: launcher/qs/notifications) and exclude `triton-desktop`.

### H6. `implicitHeight` of QsWindow doesn't track page changes; panel can be cut off
**File:** `quicksettings/QsWindow.qml:19`
`implicitHeight: panel.implicitHeight + 78` is fine as a binding, but the layer surface's size is fixed at map time in some compositor versions unless quickshell re-commits — verify; more importantly `y: 72` hardcodes bar clearance while `Theme.barHeight` is 56 + margins — drift if bar metrics change. Minor but correctness-relevant coupling; use `Theme.barHeight + Theme.space[...]`.

### H7. Theme.applyUserTokens drops alpha-hex colors and never re-applies non-color tokens
**File:** `Theme.qml:113-129`
Only `color.dark` string hexes matching exactly 6 digits are applied; any 8-digit (alpha) tokens matugen or contrast logic might emit are silently skipped, and nothing outside `color.dark` (materials, radii) can ever be user-resolved despite the "user-resolved tokens" contract. Also `this[prop] =` assignments on a singleton with `property color` — writing to non-readonly props works, but the dual camelCase/snake_case write doubles binding churn (each key writes two properties, both fire change signals, repainting twice per token).
**Fix:** accept 8-digit hex; single-source the color props (alias one spelling to the other or pick one canonical spelling — the codebase itself uses both `onprimary` lowercase and `surfaceContainerLow` camelCase, see B3).

### H8. Clock uses minute precision but formats seconds-free — fine; but `Qt.formatDateTime` re-evaluates per minute with string concat in bindings — cheap, yet `SystemClock` in Clock.qml isn't shared
**File:** `bar/Clock.qml:24-27` — LOW actually; skip. (Replaced: see H8 real item below.)

### H8. Settings sliders/toggles render fake state — the majority of controls write nothing
**Files:** `settings/DisplaysPanel.qml:138-141` (scale slider hardcoded `value: 0.7`, no onMoved), `KeyboardPanel.qml:47-59` (repeat rate/delay hardcoded), `MousePanel.qml:48-51` (pointer speed hardcoded), `SoundPanel.qml:32-45` (volumes hardcoded), `BluetoothPanel.qml:30-32` and `NetworkPanel.qml:31-33` (`on: true` hardcoded, no onToggled — switch flips visually? No — TritonSwitch `on` is a one-way property; clicking emits toggled but `on` never changes since nothing writes back: the switch **cannot even move**), `PowerPanel.qml:26-40` (three power-mode rows have no interaction at all — no radio behavior), `WindowsPanel.qml:39-43` (center-column row has no control), `BarShellPanel.qml:110-117` (reveal-edge/reveal-delay rows have no controls), `AppsPanel` rows dead.
This is the settings-app equivalent of C13: most panels are mannequins. The switches that *are* wired write keys nothing reads (C8). Aggregate severity: HIGH.
**Fix:** wire each control to a store key + engine emission, or remove/cover non-functional controls behind "in progress" affordances — never ship inert controls that look live.

### H9. `blur passes 3 size 8` + shadow on every window on llvmpipe-class systems
**File:** `configs/hypr/hyprland.conf:56-76`
`start-callisto` detects software rendering but hyprland.conf statically enables expensive blur (3 passes) and shadows for everything. On the QEMU/llvmpipe target this is the single biggest GPU/CPU cost in the session, and the no-dotfiles contract means users can't turn it down. There is no material-mode application: `appearance.material` (solid/mica/glass) is selectable in AppearancePanel but nothing reads it — neither the shell nor the engine emits anything for it.
**Fix:** have callisto-apply emit blur/shadow strength into `callisto-user.conf` based on the material setting (and performance heuristics), including `blur enabled = false` for solid.

### H10. Wallpaper image cache staleness
**Files:** `Desktop.qml:42` (`cache: true`), `wallpaper/WallpaperScene.qml:17-23` (no cache control, asynchronous only)
If the image *file at the same path* changes (matugen workflows, wallpaper regeneration), `cache: true` keeps the stale pixmap keyed by URL. Also the AppearancePanel preview `Image` (`settings/AppearancePanel.qml:69-73`) is synchronous (no `asynchronous: true`) — a multi-megapixel wallpaper decode blocks the UI thread of the settings window.
**Fix:** `cache: false` on wallpaper images (or append a mtime query fragment), `asynchronous: true` everywhere a large image loads.

### H11. PowerMenu/Greeter/LockScreen use fixed pixel offsets — broken on small/large screens
**Files:** `power/PowerMenu.qml:61,86,181,212` (y: 270/420/600/690 fixed), `lock/LockScreen.qml:43` (y: 86, 250px clock, fixed offsets bottom), `greeter/Greeter.qml` (`y: height*0.22` is fine but children fixed)
On a 768px-tall panel the power menu's hints (y 690) overflow off-screen; on 4K everything crowds the top half. These are fullscreen surfaces — geometry must be proportional or anchored.
**Fix:** anchor-based/proportional layout (`anchors` + percentage offsets).

### H12. `emit_hyprland_user` writes kb_repeat etc. nothing — actually inverse: hyprland.conf static input{} fights the user config
**Files:** `configs/hypr/hyprland.conf:25-38`, `scripts/engine/callisto-apply:255-262`
The static config sets `kb_layout = us`, `follow_mouse = 1`, natural_scroll etc; the user config re-sets some of them. Since `source` is at the end, user values win at *reload* — but `hyprctl keyword` pushes in `apply_live` don't persist across restart except via the sourced file, fine. The real problem: repeat rate/delay, sensitivity, accel profile are static-only and not engine-controlled — yet KeyboardPanel implies they are. And `drag_lock = true` is a questionable default most users can't change (no settings row). Consolidate input config generation fully in the engine.

### H13. Shell starts before tokens exist is handled, but shell restart never happens on engine structural changes
Not applicable — skip. Replaced: **hyprland.conf `source` of a missing file**: `source = ~/.config/hypr/callisto-user.conf` — if the file doesn't exist (first boot before callisto-apply? No — start-callisto seeds it. But if user wipes .config), hyprland logs an error; minor. Real H13 below.

### H13. `WlrLayershell.keyboardFocus: OnDemand` unconditional on hidden windows
**Files:** `notifications/CenterWindow.qml:19`, `notifications/ToastWindow.qml:23`
Unlike other surfaces these don't bind keyboardFocus to visibility. Low practical impact since OnDemand requires a click, but inconsistent and riskier than needed; ToastWindow additionally *can't* take focus when needed (reply input!) because clicks are eaten by the C5/C10 problems — the inline reply feature is unreachable in practice.

### H14. IPC surface inconsistency
**Files:** `shell.qml:103-138`
Notifications IPC uses inline `centerOpen = !centerOpen` while every other surface has a `toggle()` on its state singleton (and `NotificationState` lacks one). No `osd`, no `windowswitcher`, no `wallpaper` granular commands (`open`/`close`/`revert`). No bar IPC reveal-while-launcher logic — actually fine. Inconsistency makes scripting/docs error-prone.
**Fix:** uniform `toggle()`/`dismiss()` API on every state singleton; IPC handlers one line each.

### H15. `applyUserTokens` `prop in this` on a QML singleton QtObject: includes methods/meta — mostly harmless, but `key in this && key !== prop` writes snake_case duplicates doubling memory/churn; see H7. Merged.

---

## MEDIUM

### M1. Duplicated keycap/hint-row pattern copy-pasted in 6+ surfaces
`launcher/LauncherPanel.qml:280-363`, `overview/Overview.qml:292-317`, `power/PowerMenu.qml:215-272`, `windowswitcher/WindowSwitcher.qml:274-299`, `screenshot/ScreenshotUI.qml:179-204`, `wallpaper/WallpaperDock.qml:217-243` — the same "mono-font keycap rect + label" block (with `#4DFFFFFF` border, radius 7, `Math.max(24, implicitWidth+12)`) is copy-pasted at least six times with minor variations.
**Fix:** extract `components/KeyCap.qml` and `components/HintRow.qml`.

### M2. Duplicated pill-button pattern
"48px radius-24 pill with icon+label and MouseArea" appears in QuickSettingsPanel (`All settings`, power), ClipboardPanel (`Paste`, `Copy as file`), NotificationCard action buttons, OSD Saver button — at least 8 copies. `TritonButton` exists but half the surfaces don't use it because it's height-40-only. Fix: parameterize TritonButton by height/size or add a `PillButton` variant; migrate copies.

### M3. `TritonText` font.family concatenation bug for Regular weight
**File:** `components/TritonText.qml:48`
`root.familyName + (weight === Regular ? "" : weightSuffix)` — but `weightSuffix` already returns `""` for Regular. Dead conditional, harmless. But deeper: `font.family` e.g. `"Google Sans Flex Medium"` depends on the family being registered under that exact name; devshells load inconsistent font subsets (some lack `GoogleSansFlex-Medium` or `-SemiBold` or `JetBrainsMono-Medium` — e.g. `devshell-clipboard.qml` loads only `JetBrainsMono-Medium`, `devshell-notifs` only `-Regular`), so dev harnesses silently render wrong weights. Fix: one shared `DevFonts` component or a qmldir-singleton font loader.

### M4. Hardcoded color literals everywhere instead of tokens/derived alphas
White-alpha literals `#1FFFFFFF` (white .12), `#17FFFFFF` (.09), `#4DFFFFFF` (.3), `#26FFFFFF`, `#2EFFFFFF`, `#33FFFFFF`, `#0FFFFFFF` appear 40+ times across panels — these are state/surface materials that belong in Theme as named tokens (`Theme.veil` exists and *is* used sometimes, inconsistently). Hardcoded non-white accents: `#8CD6A0`/`#00391B` (success green in NotificationCard), `#C793000A` error-glass, `#3a3c41` bell ring, `#B3000000` name pill, `#16356F` preview backdrop, `#40000A1E` power veil. Theme already centralizes `veil`/`veilBright`; extend the token set (surfaceTint01..04, success colors) and sweep.

### M5. `clip: true` overuse
`LauncherPanel.qml:119`, `QuickSettingsPanel.qml:48`, `NotificationCenter.qml:29`, `ClipboardPanel.qml:44`, `WindowSwitcher.qml:33`, `SettingsWindow` (twice: root + content area), `Osd.qml:55` — clipping forces offscreen render passes per clipped subtree in scenegraph terms. Several are justified (rounded panels cropping content), but the OSD clip is dubious (nothing overhangs if WaveShape scaling is correct), and the double clip in SettingsWindow is redundant. Audit each; prefer rounding-aware containers.

### M6. Repeater-in-Repeater / heavy static mock content inside production components
`overview/Overview.qml` renders per window-thumbnail a Repeater of 12 mock content lines inside a Repeater of windows inside a Repeater of ribbons — in production this is pure waste since real thumbnails will replace it, but until then every overview open instantiates dozens of junk nodes. Same in `WindowSwitcher` (5 lines × N cards). These mock visuals should live only in devshells — production components should render empty states.

### M7. PowerMenu segment width animation on `width` + `Behavior` pattern
`power/PowerMenu.qml:101` animates width inside a Row — triggers relayout of all siblings each frame (cheap here, 5 items, acceptable). But `TritonButton radius` Behavior and `TritonSwitch` x/width/height/y animations animate layout-affecting properties; trivial cost at these sizes — note only. The board's own comment says springs can't be represented — fine. LOW-MED.

### M8. `visible` bindings missing on Island children when bar hidden
Bar visibility flips the whole window — fine. But `Bar.qml:98` `visible:` expression doesn't include any handling for `LauncherState.open` in hidden mode semantics documented in comment; behavior matches comment though. Skip — informational only. Replaced: **WorkspacePill width changes (`active ? 56 : 40`) inside a Row cause the whole island to relayout** — acceptable. Skip. Real M8 below.

### M8. Settings window panel switching keeps all 14 panels alive simultaneously
**File:** `settings/SettingsWindow.qml:48-111`
All panels are instantiated eagerly and merely `visible`-toggled. Every panel's bindings (including `SettingsService.get` store lookups) stay live permanently. AppearancePanel's 200px preview image decodes at window creation even if never opened. Fix: `Loader` per panel or a single `Loader` with `sourceComponent` keyed by `root.panel` (with `keep-alive` on the heavy ones if needed).

### M9. `SettingsService.get` in bindings re-evaluates wholesale
Every `SettingsService.get(...)` binding re-runs on *any* store change (store object identity changes each write). Fine at this scale, but the copy-on-write full-document JSON serialize+parse per keystroke (`set()` does `JSON.parse(JSON.stringify(store))` + full-file write + full process spawn + matugen run for appearance keys) means dragging a slider spawns `callisto-apply` (and potentially matugen) per tick — see H1. Even when serialized properly, the engine itself needs a "did the relevant section change" fast path: currently *every* settings write regenerates GTK css, foot theme, tokens, and hyprland conf — and for accent-affecting keys spawns matugen (30s timeout subprocess!). Fix: debounce + dirty-section-aware emission in callisto-apply (skip matugen when accent/wallpaper unchanged).

### M10. callisto-apply: foot/gtk emitters mix hardcoded values with tokens
`emit_foot_theme` hardcodes regular1/2/3/5/6, bright1/2/3/5/6/7 hex values — if these are part of the identity they belong in tokens.json; as-is they're magic constants duplicated nowhere else (unmaintainable). `--init` documented in usage line but never implemented (`--init` parsed nowhere — `DRY` is the only flag read). Dead CLI surface.

### M11. `Theme.qml` dual spelling nightmare
Both `onprimary` and `primaryContainer`/`primary_container` variants coexist; usage across the codebase is inconsistent (`Theme.onprimarycontainer` lowercase in Bar/StatusGroup vs `Theme.onprimarycontainer` same — but `Theme.onerrorcontainer`, `Theme.onsecondarycontainer` lowercase-only while camelCase `surfaceContainerHighest` is the only spelling for surfaces). The generator emits both for some roles and one for others (`onprimary` has no camelCase variant!). Anyone writing `Theme.onPrimary` gets `undefined` silently → black/invisible text, no error. Fix: pick camelCase as canonical everywhere, regenerate, sweep usages.

### M12. `Icons.qml` unused-import weight; `Icons.musicNote || Icons.terminal` defensive nonsense
`devshell-overview.qml:46` `Icons.musicNote || Icons.terminal` — musicNote exists; the `||` masks real missing-icon bugs. Several Icons entries dead (`deleteIcon` weird name due to `delete` keyword — fine but inconsistently named vs `publicIcon` for `public`). LOW-MED.

### M13. LauncherPanel key navigation: `Keys.forwardTo` indirection likely wrong ordering
**File:** `launcher/LauncherPanel.qml:152-198`
`TextInput` consumes Left/Right/Home/End internally; `forwardTo` delivers events to `queryNavKeys` *before* the input's own handling (correct per Qt docs — forwarded items get first crack), so Up/Down/Return/Escape interception works. But: text input also uses Up/Down? No — single-line input ignores them, fine. The real bugs: (a) `Tab` is advertised in the footer ("actions") but `keyPressed` doesn't handle Tab at all — dead hint; (b) `Alt+Enter` "reveal" same; (c) `console.log` debug spam in production paths (`KEY:`/`NAVKEY` lines, plus a 2-second debug Timer at lines 91-96 that never stops logging in production). Fix: implement Tab/Alt+Enter or drop the hints; remove debug logging.

### M14. `NotificationState` groups never sort/trim; `countText` only set at creation
`rebuildGroups` sets `countText: "1"` only for new groups; on increment `count` bumps but `countText` is copied stale via `Object.assign` — center shows "1" forever for multi-notification apps (CenterWindow prefers `grp.countText || String(grp.count)` so the stale string wins). REAL BUG — upgrade to HIGH-ish; keep here as M14 with correctness note. Fix: recompute countText on every increment or drop it and format in the view.

### M15. devshell files duplicated boilerplate (~70 lines × 10 files)
Each devshell re-declares FontLoaders and PanelWindow scaffolding. Extract `devshell/DevHarness.qml`. Also `intertest.qml.bak` committed junk, `components/DevTestWindow.qml` dead file, `devshell.qml` loads both JetBrains Regular+Medium+SemiBold while others don't (M3).

---

## LOW

### L1. `bar/BellButton.qml:39-40` magic positioning arithmetic with unexplained `-2` stroke offsets; extract named constants.
### L2. `bar/WorkspacePill.qml` uses raw `Text` + literal `"Jost SemiBold"` instead of TritonText atoms (same in `bar/WaveButton.qml:39` raw Text for icon instead of TritonIcon). Violates the components' own contract.
### L3. Magic numbers pervasive: `6` island edge padding (documented as deliberate), `72` bar-zone clearance in QsWindow/ToastWindow, `44`/`22` radii literals that are `size/2` — use expressions or tokens.
### L4. `ToastWindow.qml:20` `implicitHeight: toastCol.implicitHeight + 84` — binding loops the window height to content while content depends on window? Not a loop, but when toasts shrink the window shrinks and re-maps; combined with C10 input-eating, transient dead zones. Minor.
### L5. `screenshot/ScreenshotUI.qml:108-116` corner-handle math is convoluted and partly wrong-looking (`modelData.x + (w === 26 ? 0 : 0)` is a no-op expression); rewrite clearly.
### L6. `hyprland.conf`: duplicate-ish layerrule regexes (`quickshell` vs `^(quickshell)$`); `no_anim` on all shell surfaces prevents any future compositor-side animations; `animation = border, 0` disables border anim with missing speed param style inconsistency; `col.active_border rgba(b0c6ff66)` static default immediately overridden by user conf/engine — fine but drift source. `bind = $mod SHIFT, C, killactive` duplicates `$mod, Q`. `swaybg` (see C15). Missing keybinds: quicksettings toggle, settings toggle, wallpaper picker — features unreachable by keyboard.
### L7. `start-callisto`: `systemd-detect-virt -q` inside `elif` returns nonzero for non-VM bare metal — fine logically. `ls file >/dev/null` instead of `[[ -f ]]`. Minor style.
### L8. `Greeter.qml:365-367` power button color `#CC7C3114` hardcoded; sessionName default `"niri"` (!!) — leftover from the niri-based inspiration, wrong for a Hyprland product and visible in UI.
### L9. `Osd.qml:60-63` width ternary chain unmaintainable; variant-width table would be clearer. `Osd.Variant` magic numbers duplicated in OsdState comment (see C14).
### L10. `WallpaperScene` nebula/planet "circles" are giant unblurred solid ellipses — visual quality issue rather than code; the scenes don't match their descriptions ("radial violet/blue" is two flat translucent circles, not a gradient). LOW visual.
### L11. `ColorsCard.qml` region colors hardcoded (`#3C5FD6` etc.), not extracted from the actual wallpaper — the card claims "Colors from Orbit" but shows fixed values regardless of selected wallpaper; also text uses literal `#FFFFFF` instead of tokens throughout wallpaper/* (`WallpaperDock` too). Misleading UI, MED-LOW.
### L12. `TritonSwitch` has no `enabled` state; `TritonSlider` MouseArea doesn't `preventStealing`/handle touch multi-point, no wheel support, and `value` isn't updated internally (controlled-only — every user must implement; most don't, so sliders visually snap back when unbacked — part of H8's placebo effect).
### L13. `SettingsSidebar` search input emits `queryEdited` — handled by nobody (`SettingsWindow` doesn't bind it); search is dead. Same pattern as everywhere: wire or remove.
### L14. `qmldir` exposes only Theme/Icons/Desktop — components/services rely on directory imports; fine, but no `qmldir` in subdirectories means no versioning boundaries. Informational.
### L15. `intertest.qml`/`devshell*` import `components` but some don't use it; trivially dead imports across files (e.g., `import Quickshell.Io` unused? not verified per-file — noted as a sweep task).
### L16. `notifications/CenterWindow.qml` doesn't pass `toggleGroup`/`hiddenCount` interactions (see C17) and doesn't close on Esc/click-off (no key handling at all — `keyboardFocus OnDemand` but nothing consumes Esc).
### L17. `bar/Bar.qml` `PwObjectTracker` created unconditionally even when sink null — fine. `hasSink` chain `sink?.audio !== null && !== undefined` verbose; `!!sink?.audio` equivalent. Style.
### L18. `hyprland.conf` missing `xwayland`/`misc` focus-or-activate settings; `vrr = 1` global while DisplaysPanel implies per-display control — drift. Noted.
### L19. `services/OsdState.qml` `show()` silently drops unknown payload keys (`if (k in root)`) — typos in producers vanish; at least warn.
### L20. `callisto-apply` never reloads or signals gtk/foot consumers (gtk css is picked up only at app start — expected; foot reloads? foot does watch? — verify). matugen `--prefer darkness` flag: verify it exists in the matugen version pinned; wrong flag = subprocess exception = silent fallback. Defensive but unverified — flag for testing.

---

## TOP 15 fixes by impact-to-effort

1. **C8 — unify settings sections (`input.*`)** between Mouse/Keyboard panels and the engine. One-line-per-control fix; unbreaks the entire input settings chain.
2. **C9 — pass `effective` into `apply_live`** instead of re-reading tokens.json. ~5 lines; fixes wrong-colored borders everywhere, every accent change.
3. **C1 — write/clear both wallpaper channels** in `preview()`/`commit()`. ~6 lines; unbreaks wallpaper switching permanently.
4. **C5 — move NotificationCard dismiss MouseArea behind content** (or z-order). One-line-ish; unlocks reply/actions in all notifications.
5. **C4 — delete the singleton expireTimer**, rely on per-card timers already in ToastWindow. Deletion; fixes zombie toasts.
6. **C15 — remove swaybg exec-once** from hyprland.conf. One line; removes double wallpaper.
7. **C11 — bind WallpaperWindow keyboardFocus to visible.** One line; removes potential focus-steal soft-lock.
8. **C7 — wire power actions to systemctl/loginctl.** ~15 lines; makes the only power UI real.
9. **C17/M14 — implement `NotificationState.toggleGroup` + fix stale `countText`.** ~10 lines; unbreaks center expansion and counts.
10. **M13 — strip debug console.logs/Timer from LauncherPanel and implement/remove dead Tab/Alt+Enter hints.** Small; stops production log spam and false affordances.
11. **C14 — add volume/mute observer → OsdState.show + an osd IPC target; kill the variant magic numbers.** ~40 lines; makes the OSD exist at all.
12. **C10 — constrain input regions / size windows to content + click-off dismiss for QS/center.** Medium effort, huge usability correctness win (dead input zones along screen edges).
13. **C12 — sync WallpaperWindow `applied`/`selected` from the store on open.** ~10 lines; correct initial picker state.
14. **C6 — instantiate the lock screen via session-lock (or remove the lock keybind until then).** Biggest single missing feature; highest effort on this list but security-critical — at minimum, *remove `Super+Escape` lock bind* if unfixed (1 line) so users aren't stranded.
15. **M9 — debounce store writes + dirty-section-aware engine emission** (skip matugen unless accent/wallpaper changed). ~30 lines split between SettingsService.qml and callisto-apply; turns slider drags from a process-spawn storm into one apply.

Honorable mentions just outside the cut: **C2** (launcher backend — high impact, high effort: the single biggest feature gap), **H1** (write serialization — prerequisite for #15 to be fully correct), **C13/H8** (wire QS + settings controls to real services — large effort, do incrementally after 1/15), **C16** (one-line property redeclaration fix — verify first whether it errors at runtime; if it errors, it's effectively free to fix and belongs in the top 5).
