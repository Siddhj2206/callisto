# Quickshell Architecture & Performance Research

Research for the **Triton** shell (Quickshell 0.3.0 / Qt6 / Hyprland).
Compiled 2026-11-26. Primary sources: Quickshell 0.3.0 official docs and changelog, the Qt 6
performance guide, and direct source inspection of the two largest production shells:
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) ("ii" shell) and
[caelestia-dots/shell](https://github.com/caelestia-dots/shell).

Version target note: **0.3.0 is the target API ceiling** (Debian trixie-backports). Where a
feature/fix only exists in 0.3.1+ it is flagged with **[>0.3.0]**.

---

## 1. QML / Quickshell performance

### 1.1 Loader vs inline, lazy loading

The single most-cited optimization, both in the official FAQ and in every production shell, is:

- **Use `LazyLoader` (Quickshell type) or Qt's `Loader` for everything not needed at first paint.**
  The FAQ's answer to "reduce memory usage" is literally "use Loaders": use `Loader` if the root
  of the component inherits `Item`, otherwise `LazyLoader` (windows, `Scope`s — non-visual roots).
  <https://quickshell.org/docs/v0.3.0/guide/faq>
- `LazyLoader` semantics that matter for architecture
  (<https://quickshell.org/docs/v0.3.0/types/Quickshell/LazyLoader>):
  - `loading: true` starts **asynchronous** background loading in spare frame time; `active: true`
    forces synchronous completion. `activeAsync` is the "set and forget" async variant.
  - Accessing `.item` while it is still loading **blocks the UI thread** — either wait for
    `activeChanged` or accept the block deliberately.
  - **Caveat:** `Variants` does *not* support async loading in 0.3.0 — putting `Variants` inside a
    `LazyLoader` still blocks like no loader at all. Since `Variants` is the standard per-monitor
    pattern, per-monitor window trees effectively load synchronously; design startup accordingly
    (keep per-monitor trees light, lazy-load the interiors instead).
  - On hot reload, lazy loaders load **synchronously** so windows can be reused — reload cost is
    proportional to what's currently active, not what's merely defined.
- Both production shells gate panels on config-readiness:
  end-4 defines a `PanelLoader` (`LazyLoader` with `active: Config.ready && extraCondition`) and
  instantiates *every* panel family member (bar, dock, lock, OSD, sidebars…) through it. Caelestia
  keeps static modules inline at the `ShellRoot` but lazy-loads interiors (e.g. bar content
  `Loader { active: root.shouldBeVisible }`). Two valid strategies:
  - **end-4 style:** everything behind loaders, maximal laziness, faster startup.
  - **caelestia style:** panel *windows* always exist (empty, zero-size), *contents* load on demand.
    This keeps window/surface identity stable (useful for popups anchored to bar items) at the cost
    of more idle wayland surfaces.

### 1.2 Binding hygiene (Qt's own perf guide — all directly applicable)

Source: <https://doc.qt.io/qt-6/qtquick-performance.html>

- **Property resolution cost:** repeated `obj.color.r/g/b` style lookups each allocate a JS
  value-type wrapper and run the C++ getter. In hot bindings/functions, cache the base object in a
  `var` once. This applies directly to singleton lookups: `Config.options.bar.x` re-walks the
  object chain each time it's evaluated — in *bindings* this is fine and necessary (the dependency
  tracking is the point), but inside **loops and frequently-invoked JS functions** hoist the lookup.
- **Binding re-evaluation granularity:** a binding is re-run when *any* property it references
  changes. Keep bindings small; accumulate into temporaries and assign once instead of incrementally
  updating a property others bind to.
- **Sequence/value-type churn:** `listProperty[j] = x` on a C++-backed sequence (e.g. anything from
  Quickshell's own types like `Hyprland.workspaces.values`) does a full read-modify-write of the
  whole sequence **per element write**. Build a plain JS array copy, mutate, assign back once.
  Same class of issue for value types (`color`, `font`, `rect`).
- **Intermediate binding pattern:** if N bindings all depend on `someList[1]`, every list change
  re-evaluates all N. Add one intermediate `property var elem: someList[1]` and bind to that — only
  the intermediate re-evaluates.
- **Anchors > bindings for positioning.** Static x/y/width/height initialization beats anchors beats
  imperative bindings, in that order, for cost.
- **Never run JS per animation frame** (no script animations); animating a property re-evaluates
  all dependent bindings every frame — sometimes it's worth breaking the binding during the
  animation and re-binding after.

### 1.3 Text, images, rendering

- `Text` layout is expensive: use `textFormat: Text.PlainText` wherever possible (default is
  `AutoText` which pays a parse cost; `RichText` is worst). Icon fonts and clocks should be plain.
- `Image`: `asynchronous: true` for anything non-trivial; **always set `sourceSize`** when
  displaying a large image small (wallpaper thumbnails in launchers/pickers are the classic
  shell hotspot — without `sourceSize` the full-resolution decoded pixmap is kept in memory per
  delegate). `smooth: false` if no scaling. Changing `sourceSize` reloads the image — don't
  bind it to animated geometry.
- Qt Quick scene graph: clipping is a cost, not an optimization — **never set `clip: true` on a
  ListView delegate**, avoid it generally unless visually required (it defeats render reordering).
  Prefer `Item` over `Rectangle` as a pure container root (no background paint). Keep translucent
  pixels out of large surfaces where opaque works — blending cost, and note Quickshell's behavior:
  an opaque window background color makes Quickshell pick an opaque surface format (cheaper GPU);
  if you need transparency at all, set `QsWindow.surfaceFormat { opaque: false }` once rather than
  flip-flopping colors.
- Avoid `ShaderEffect` in delegates; `ShaderEffectSource` (renders scene into an FBO first) is
  expensive — this is what live blur/vibrancy-style effects cost. Prefer static pre-composited
  assets (shadows etc.).

### 1.4 Compile/bytecode caching — what applies to Quickshell

- **`qmlcachegen` does not apply**: it is an AOT compiler for application-bundled (qrc) QML.
  Quickshell configs are runtime-loaded file trees, so there is no ahead-of-time step.
- What *does* apply: Qt's **QML disk cache** (`QQmlDiskCache`). Since Qt 5.11 the engine caches
  compiled QML/JS units to disk automatically (default under the XDG cache dir). Qt 6 additionally
  optimizes many simple bindings/functions at compile time when files are written in the modern
  style — this is why **`pragma ComponentBehavior: Bound`** matters (both production shells put it
  in every file): it makes delegate context explicit, enables better compiled bindings, and
  avoids slow dynamic context lookups. **Uncertainty:** the exact cache directory for
  file-system-loaded QML under Quickshell, and whether Quickshell overrides it, is not documented;
  0.3.0 added the ability to override `Quickshell.cacheDir` (`//@ pragma CacheDir`), which is the
  shell-level state/cache, distinct from the engine cache. Practical advice: don't fight it —
  the cache is automatic; focus on making units *compilable* (typed function signatures,
  `Bound` components, no dynamically-scoped lookups) which is what actually speeds re-evaluation.
- Related 0.3.0 feature: **`//@ pragma DropExpensiveFonts` / `QS_DROP_EXPENSIVE_FONTS=1`** —
  excludes woff/woff2 fonts which cause stutters and high memory use. Caelestia sets this. Also
  relevant: load icon/symbol fonts once at the root (`FontLoader` in `shell.qml`) instead of
  per-widget.
- **Icon lookup caching:** `Quickshell.iconPath()` goes through Qt's `QIcon::fromTheme`, which
  maintains its own theme index cache after first scan — lookups are cheap after warm-up but the
  first scan can be slow; 0.3.0 also added a way to detect whether an icon came from the system
  theme. **Uncertainty:** no official statement on cross-reload persistence of the icon cache.
  Practical pattern from end-4/caelestia: centralize icon resolution in one `Icons`/`Images`
  utility singleton so the theme is hit through consistent keys.

### 1.5 Memory / GC

- Each element that declares custom properties becomes its own **implicit type** (extra engine
  metadata + JS heap). If several elements share the same custom-property shape, extract a real
  component (file or inline `component Foo: Item {}`) — the Qt docs explicitly recommend this.
- Qt's guide: prefer singleton **types** over `pragma library` JS for app-wide state — less JS
  heap, better performance. (Quickshell's `Singleton` QML type is exactly this pattern; both
  production shells use QML singletons, not library scripts, for all services.)
- JS garbage collection is incremental since Qt 6.8 (shorter but more frequent pauses). Implication:
  avoid allocating objects/arrays/closures in bindings that fire per frame or per millisecond tick
  (clocks, volume peak meters). E.g. end-4's `DateTime`/system-stats services parse into
  pre-declared properties rather than rebuilding object graphs.
- Destroy what you unload: reset `Loader.sourceComponent`/set `active: false`; don't rely on GC.
  Don't call `gc()` manually (full non-incremental collection, hundreds of ms pause).

### 1.6 Models & views

- Short, bounded lists (tray icons, workspaces, MPRIS players): **`Repeater`** inside a Row/Column
  layout — or better, Quickshell's **`ObjectModel`**, which lets you declare heterogeneous children
  declaratively and reuse them as a model for views/repeaters (used heavily by end-4 for bar
  sections).
- Long/scrollable/unbounded lists (launcher results, notifications): **`ListView`** — delegates are
  pooled/recycled. Enable delegate reuse (Qt 6 `reuseItems`); keep delegates minimal, few bindings,
  anchors only, no clip, no shaders. Set `cacheBuffer` for non-trivial delegates.
- `ListModel` (QML) is fine for small prototypes; avoid `dynamicRoles`. For filtered/search views,
  compute the filtered array in a singleton service and assign it wholesale (single assignment,
  one re-evaluation wave) — this is what caelestia's `Searcher.qml` and end-4's
  `LauncherSearch.qml` do. **Note:** Quickshell ships `ScriptModel` for transforming object lists
  reactively, but [>0.3.0] 0.3.1 fixed crash bugs in it (`ScriptModel` misuse could launder freed
  objects — be careful in 0.3.0; prefer plain array recompute).
- **"surface pooling"** — there is no layer-shell surface pool API in Quickshell; what people mean
  in practice is the caelestia pattern: keep the `PanelWindow` alive permanently and toggle
  visibility/content loaders rather than recreating the window. Window creation involves a full
  layer-shell round trip; visibility flips do not. Trade memory (surfaces always exist) for
  latency (instant popups). For OSD/launcher — the latency-critical panels — this is the right
  trade.

### 1.7 Idle CPU / battery

- Qt Quick only renders when the scene graph is dirtied. A correctly-built shell with no running
  animations should sit at **~0% CPU** when idle. Practically, end-4-style shells idle at a small
  fraction of one core; if you see constant 5–15% idle CPU, something is animating invisibly or a
  timer is redrawing.
- Concrete rules:
  - **Stop animations when invisible.** `visible: false` items skip rendering but *still evaluate
    bindings and animations* — unload or at least stop `running` on Behavior/animators in hidden
    panels. NumberAnimations on invisible OSDs are the classic leak.
  - **1 Hz is enough for clocks.** Use `Quickshell.SystemClock` (it aligns updates to minute/second
    boundaries — designed exactly for bar clocks) instead of free-running `Timer`s.
  - Set `QsWindow.updatesEnabled` carefully — [note: its redraw-on-true behavior was fixed in
    0.3.1; in 0.3.0 windows may not redraw when re-enabled — test before relying on it].
  - Minimize repaint *regions*: prefer small animating elements inside large static windows; a
    full-width bar that repaints because of one blinking icon is worse than isolating the animating
    item (scene graph does dirty-region culling per item, not per pixel).
  - Polling timers are the other classic: pipewire/mpris/hyprland data in Quickshell is
    **event-driven already** (see §4); only poll what truly has no event source (some sysinfo).

### 1.8 Profiling tools

- **QML Profiler** (Qt Creator / Qt VS Code extension): the definitive tool — shows binding
  re-evaluations, JS hot spots, scene graph compile times. Requires starting the app with the
  qmljsdebugger (`-qmljsdebugger=port:...`). **Uncertainty:** whether Quickshell forwards/accepts
  the debug enabler cleanly — community reports indicate you can pass it via environment; verify
  on target before planning around it.
- **`qs log`** — Quickshell's own log viewer (`qs log`, including following dead/crashed
  instances since 0.2). Quickshell writes detailed logs per instance; this is your first stop.
- **`QSG_VISUALIZE` env vars** (works in any Qt Quick app): `QSG_VISUALIZE=overdraw`,
  `=batches`, `=changes` (flashes regions that repaint — perfect for finding unintended repaints),
  `=clip`. Settable via `//@ pragma Env` in dev.
- **`QML_IMPORT_TRACE=1`** for module-resolution debugging; `QT_LOGGING_RULES` for category noise.
- **GammaRay** (KDAB) can attach to a running Qt process and inspect the item tree, bindings,
  scene graph and memory — works on Qt6 apps; the standard deep-inspection tool for "which of
  my 400 items is re-evaluating".
- **`QSG_RENDER_LOOP=threaded`** — caelestia sets this via `//@ pragma DefaultEnv`; on Linux the
  threaded render loop is default in most configurations already, but setting it explicitly is
  harmless insurance (keeps animations smooth when the GUI thread stalls briefly).

---

## 2. Architecture of real production shells

### 2.1 end-4/dots-hyprland ("ii" shell) — the maximalist monorepo pattern

Layout (`~/.config/quickshell/ii/`):

```
shell.qml                  # ShellRoot: pragma header, panel-family switching, IPC/shortcuts
GlobalStates.qml           # singleton: global UI state (barOpen, screenLocked, superDown...)
ReloadPopup.qml
services/                  # one Singleton per domain: Audio, Battery, Brightness, HyprlandData,
                           #   MprisController, Notifications, LauncherSearch, ResourceUsage...
modules/
  common/                  # cross-panel shared layer:
    Config.qml             #   JSON-backed config singleton (see below)
    Appearance.qml         #   theme singleton: colors, sizes, rounding, fonts, animation curves
    Directories.qml        #   XDG paths
    widgets/               #   reusable styled widgets (buttons, text fields, switches...)
    functions/ models/ utils/ panels/
  ii/                      # the "ii" panel family: bar/, dock/, lock/, onScreenDisplay/,
                           #   overview/, sidebarLeft/...  one directory per panel
  waffle/                  # a SECOND complete panel family (Windows-11-style) reusing common/
panelFamilies/             # Scope per family; PanelLoader = LazyLoader gated on Config.ready
settings.qml, welcome.qml  # separate shell entries (separate qs invocations)
```

Key patterns:

- **Config**: `modules/common/Config.qml` — a `Singleton` wrapping `FileView` + `JsonAdapter`
  (both Quickshell 0.3 types). `property alias options: jsonAdapter` — the whole shell binds to
  `Config.options.<dotted.path>`; `watchChanges: true` live-reloads when the user edits the JSON;
  writes are **debounced through 50 ms Timers** (`readWriteDelay`) to avoid write/read feedback
  storms. `Config.ready` gates all `PanelLoader`s so nothing instantiates before config is parsed.
  Defaults ship in the JsonAdapter definition itself, so the file can be sparse.
  `setNestedValue()` helper converts string values back to typed JSON — used by the settings GUI.
- **Theming without hardcoding**: `Appearance.qml` singleton exposes semantic tokens —
  `Appearance.colors.colPrimary`, `Appearance.sizes.barHeight`, `Appearance.rounding.*`,
  `Appearance.animation.curves.*` (including expressive/standard MD3 curves as lists for
  `EasingCurve`). Colors are *generated* (matugen/Material-You pipeline writing a theme file that
  `MaterialThemeLoader` loads) — i.e. **the theme is data, not code**. Nothing visual hardcodes a
  hex color; everything binds to `Appearance.colors.*`.
- **Multi-monitor**: `Variants { model: <filtered Quickshell.screens> ; delegate: LazyLoader {
  required property ShellScreen modelData; component: PanelWindow { screen: loader.modelData ... }}}`.
  Screens can be filtered by config (`Config.options.bar.screenList`). The bar is a `Scope`
  containing the `Variants` so shared logic (timers, connections) exists once, not per monitor.
- **Lazy panel families**: entire alternative UI families selected at runtime by swapping the
  active component in a `LazyLoader` — demonstration that the shell can treat even *the bar*
  as a hot-swappable component when common/ is properly decoupled.
- **State**: `GlobalStates` singleton holds ephemeral cross-panel UI state (`barOpen`,
  `screenLocked`, osd triggers); domain state lives in `services/`. Clean split: *services* =
  system truth, *GlobalStates* = shell UI truth, *Config* = user preference truth, *Persistent* =
  values that must survive restarts.

### 2.2 caelestia-dots/shell — the modular monolith with C++ backing

Layout (repo root IS the shell dir):

```
shell.qml          # ShellRoot: pragma header incl. QS_DROP_EXPENSIVE_FONTS, QSG_RENDER_LOOP,
                   #   crash-report URL; eagerly touches singletons (Notifs; Players;) to
                   #   pre-warm them at startup instead of lazily
modules/           # bar/ launcher/ osd/ lock/ notifications/ dashboard/ drawers/ utilities/...
components/        # shared styled widgets (the "common/widgets" equivalent)
services/          # Singletons: Audio, Brightness, Hypr, Notifs, Players, Time, ShellState...
utils/             # Icons, Images, Paths, Strings, SysInfo, Searcher
daemons/           # always-running logic objects (BatteryMonitor, IdleMonitors, GameMode...)
plugin/            # C++ QML plugin (CMake): Config, Services, Models, Shaders, I18n,
                   #   circular buffer, calculator — performance-critical pieces in C++
```

Key differences from end-4 worth stealing:

- **C++ plugin for hot paths**: `Caelestia.Config` is a C++-backed config system; tokenizer
  (`Tokens.padding.large`, `Tokens.sizes.*`, Material-3-style design tokens) likewise. Theming is
  still data-driven, but lookups skip QML/JS entirely. For Triton, this is a "phase 2" option —
  pure-QML config à la end-4 is fine; measure before adding a build step.
- **Per-screen `ScreenState` object**: instead of one global "osd visible" flag, each monitor
  gets a state object passed down as a `required property` — multi-monitor-aware visibility
  (OSD shows on the focused screen, not all). Components receive `required property ShellScreen
  screen` + `required property ScreenState screenState` — explicit dependency injection instead
  of reaching into globals.
- **Drawers architecture**: one `Variants { model: Screens.screens }` creates one `Scope` per
  screen containing `Exclusions` + a single `ContentWindow` per monitor — bar/OSD/notifications
  coordinate exclusion zones through shared per-screen infrastructure rather than each window
  managing struts independently.
- **OSD trigger pattern**: `Connections` on service signals → `show()` → restart hide timer;
  position animated via an offset property with a `Behavior`, content `visible` bound to the
  animated value so it's only evaluated while transitioning. Clean, no hardcoded timings.
- **Pre-warming**: `Component.onCompleted: { Notifs; Players; Brightness; }` — referencing a
  singleton forces instantiation. Decide per-service: lazy (fast startup) vs eager (no first-use
  hitch). Rule of thumb: eager for event-driven services that must not miss events (notifications,
  pipewire), lazy for everything user-triggered.

### 2.3 Shared patterns across both (the consensus architecture for Triton)

1. **Singleton taxonomy**, three-plus-one layers:
   - `Config` — user preferences, JSON-backed via `FileView`+`JsonAdapter`, debounced writes,
     `ready` gate.
   - `Appearance`/`Tokens` — pure presentation tokens (colors, sizes, radii, animation curves).
     No logic. Everything visual binds here; nothing hardcodes.
   - `services/*.qml` — one singleton per external system (Audio, Brightness, Network, Hyprland,
     Notifications, Battery). These own IPC/D-Bus/Process objects and expose clean reactive
     properties. UI never talks to the system directly.
   - `ShellState`/`GlobalStates` — ephemeral UI state (which panel is open, lock state).
2. **`modules/<panel>/` per panel** (bar, launcher, osd, quicksettings, lock), each internally
   split into a thin window-wrapper file and content files; **`modules/common` or `components/`**
   for shared widgets. Panels import upward (common) never sideways (bar importing launcher).
3. **Per-monitor via `Variants` + `Scope`**, `required property ShellScreen modelData` passed
   down as `screen`; `pragma ComponentBehavior: Bound` in every file.
4. **Everything latency-critical pre-created**: launcher/OSD windows exist persistently (hidden),
   contents behind `Loader`/`active` so first-open is instant but idle memory stays low.
5. **Pragma header in shell.qml**: version-agnostic env setup — `QS_NO_RELOAD_POPUP`,
   `QS_DROP_EXPENSIVE_FONTS`, controls style, optionally `QSG_RENDER_LOOP`. 0.3.0 adds
   `//@ pragma DefaultEnv` (set only if unset) — prefer it over `Env` for anything the user
   might legitimately override.
6. **Version gating exists in 0.3.0**: `//@ if hasVersion(major, minor, features)` preprocessing
   and `Quickshell.hasVersion()` — use this if Triton ever needs to tolerate multiple Quickshell
   versions rather than forking code.

---

## 3. Reusable component design in QML

Patterns observed and Qt best practice:

- **`required property` for injected dependencies** (screen, screenState, modelData): fail-fast at
  creation instead of null-binding surprises, self-documenting interface. Caelestia uses this
  pervasively; combine with typed properties (`required property ShellScreen screen`).
- **`property alias` to expose interior** when the consumer legitimately needs it
  (end-4: `property alias options: configOptionsJsonAdapter` — one authoritative object,
  no synchronization code). Alias is zero-cost compared to a re-binding.
- **Parameterize through plain properties with sane defaults**; style through the theme singleton,
  not through per-instance color properties. Anti-pattern seen in the wild: widgets exposing
  `property color color1...color7` — every consumer re-hardcodes the theme. Better: widget binds
  `Appearance.colors.*` internally and exposes *semantic* toggles (`property bool flat`,
  `property int padding` defaulting to `Appearance.padding.normal`).
- **`default property alias content`** / using the default property for children makes composite
  containers nest naturally (both shells' `BarGroup`, `StyledRect` etc.).
- **Attached properties / objects**: Quickshell itself uses attached objects
  (`toplevel.HyprlandToplevel`, `QsWindow` attached object). For Triton, attached properties are
  appropriate for cross-cutting concerns (e.g. "this item participates in focus grab") — but a
  plain function call in `Component.onCompleted` (end-4's `GlobalFocusGrab.addPersistent(root)`)
  is simpler and was chosen in practice. Don't over-engineer.
- **Anti-patterns to avoid** (observed in smaller community configs):
  - Reaching into other components by `id` across file boundaries (implicit coupling; breaks
    under `ComponentBehavior: Bound` anyway) — pass things down as required properties or up via
    signals.
  - Storing UI state in global singletons that belongs to one component (pollutes GlobalStates
    into a god-object; both shells keep it small).
  - JS arrays rebuilt per-frame in bindings; sorting/filtering inside delegates instead of in the
    service layer.
  - `Component.onCompleted` used to *initialize values that could be bindings* — onCompleted runs
    once and is invisible to the reactive system. Correct uses: one-shot side effects (service
    warm-up, registering in a focus grab, initial data fetch). Incorrect: `onCompleted: width =
    foo.width` (should be a binding). end-4's OSD does use onCompleted to snapshot initial values
    (`volume = Audio.volume`) — that's deliberate: capture-once vs track-continuously semantics.
  - Overly deep binding chains through multiple singletons in paint-critical paths
    (`Config.options.bar.a.b.c` inside a delegate in a 500-row ListView) — hoist to an
    intermediate property on the delegate root.

---

## 4. Hyprland integration without polling

Quickshell 0.3.0's `Quickshell.Hyprland` module is **natively event-driven** — it maintains the
IPC2 socket connection internally and exposes reactive object models:

- `Hyprland.workspaces` / `.toplevels` / `.monitors` — live-updating object models (with
  `.values` arrays), `Hyprland.activeToplevel`, `Hyprland.focusedWorkspace`,
  `Hyprland.focusedMonitor`, `Hyprland.monitorFor(screen)`. Bind directly; no polling anywhere.
- `Hyprland.dispatch("workspace 2")` for commands; `Hyprland.rawEvent` signal for anything not
  modeled. 0.3.0 also added lua-config support (`Hyprland.usingLua` — dispatch syntax differs;
  caelestia branches on it, worth copying verbatim).
- `ToplevelManager` + the `HyprlandToplevel` **attached object** (added 0.2) is the compositor-
  agnostic way to enumerate windows; use `HyprlandToplevel.address` to correlate.

The two real-world consumption styles:

1. **Caelestia style (preferred for Triton):** pure reactive bindings off the built-in models,
   zero external processes. Their `services/Hypr.qml` is a thin semantic wrapper (caps-lock
   state, workspace helpers, dispatch wrappers) that adds *derived* state, never duplicate
   transport. **This is the correct architecture for 0.3.0** since the module covers workspaces,
   toplevels, monitors, and keyboard devices.
2. **end-4 style (legacy/extended):** `HyprlandData` singleton listens to `Hyprland.rawEvent`
   and re-runs `hyprctl clients/monitors/workspaces -j` via `Process`+`StdioCollector`, parsing
   JSON into plain JS objects — because some fields (per-window geometry, `layers` output,
   initial tile positions for the overview) are not in Quickshell's model. It is still
   **event-driven, not polled**: hyprctl invocations happen only when an IPC event arrives.
   Note the sharp edges they handle: filtering the lock-screen pseudo-workspace id range,
   rebuilding lookup maps (`windowByAddress`) wholesale in one assignment rather than mutating
   (the §1.2 sequence-write trap), and coalescing events (many raw events → multiple concurrent
   `hyprctl` runs is accepted; for Triton consider guarding `if (!getClients.running)` or
   debouncing with a short timer — end-4 does not debounce and it visibly spikes CPU on event
   storms like workspace swipe animations).

Additional integration notes:

- **`GlobalShortcut`** (0.2+) binds Hyprland `bindl` global shortcuts by name — the right way to
  trigger shell UI (no keygrab conflicts, no polling).
- **`IpcHandler`** + 0.3.0's IPC signal listeners expose shell functions to
  `qs ipc call`/`hyprctl` keybinds; use for externally-triggered toggles.
- For anything socket-shaped that Quickshell doesn't model, prefer a long-running
  `Process` with `SplitParser` (streaming parse per line) over periodic one-shot polls — the
  docs' own guidance for "a command that listens to window manager IPC".

---

## 5. Resilience: hot reload, crash recovery, logging

- **Hot reload is built in**: Quickshell watches shell files and reloads on change; 0.3.0
  skips reloads when content hasn't actually changed, and `QS_DISABLE_FILE_WATCHER` disables it
  entirely. **Keep reload-correctness in mind as an architectural constraint**: loaders load
  synchronously during reload; avoid assuming singleton initialization order across reload
  boundaries; [>0.3.0] note: 0.3.1 fixed a crash when quitting/reloading while a `Loader` was
  mid-async-load — in 0.3.0 prefer `active` (synchronous) over async for small components, or
  accept the small risk during development-only reloads.
- **Crash handler**: Quickshell ships a crash handler (cpptrace since 0.3.0) that captures a
  backtrace and can relaunch/restart; `QS_CRASHREPORT_URL` (pragma-able — caelestia points it at
  their own issue template, do the same for Triton) and `QS_DISABLE_CRASH_HANDLER` exist. Design
  consequence: **the shell process may be restarted after a crash** — state that must survive
  (volume OSD position is fine to lose; user session state, notification history, clipboard
  manager contents are not) should live in `Quickshell.statePath`/`dataPath` files or in
  `PersistentProperties` (Quickshell type that persists properties across reloads — use it for
  panel positions, user toggles). end-4's `Persistent.qml` demonstrates the pattern.
- **Logging**: `console.log` etc. go into per-instance logs viewable with `qs log` (supports dead
  instances since 0.2). Logging discipline: services log state transitions once, never in hot
  bindings (a log line per binding re-evaluation both spams and costs). For verbose dev tracing
  use `QT_LOGGING_RULES` categories rather than commented-out console lines.
- **Multi-instance safety**: shell-id derives data/state/cache dirs; 0.3.0 stopped canonicalizing
  config paths — if Triton is symlinked into place, set `//@ pragma ShellId triton` explicitly so
  the id is stable regardless of symlink layout.
- **Version-gated preprocessing** (`//@ if hasVersion(...)`) — 0.3.0 feature — lets one codebase
  tolerate distro version drift, worth using if Triton targets both backports and newer distros.
- Development loop tips from both projects: `QS_NO_RELOAD_POPUP=1` during dev; run a second qs
  instance against a copy of the config rather than reloading your live shell when testing crashy
  changes; `qs kill` + systemd user service or Hyprland `exec-once` restart for production
  supervision (Hyprland will not auto-restart it — put the restart logic in a wrapper or systemd
  unit with `Restart=on-failure`).

---

## 6. Recommendations for Triton (synthesis)

1. Adopt the consensus architecture (§2.3): `Config` (FileView+JsonAdapter, debounced, `ready`
   gate), `Theme`/`Tokens` singleton, `services/` per system, `State` for UI state,
   `modules/<panel>` with shared `components/`, `Variants`+`Scope` per monitor with
   `required property ShellScreen`.
2. Every file starts with `pragma ComponentBehavior: Bound`.
3. Bar/dock/launcher/OSD/quicksettings windows persistent, interiors lazy (`Loader.active` bound
   to visibility); per-monitor heavy trees behind `LazyLoader` accepting the synchronous first
   load (Variants can't async in 0.3.0).
4. Hyprland state purely from `Quickshell.Hyprland` reactive models; a thin semantic wrapper
   singleton à la caelestia's `Hypr.qml`. Only shell out to `hyprctl` for fields Quickshell
   lacks, triggered by `rawEvent`, debounced, wholesale re-assignment.
5. Delegate discipline for launcher lists: ListView + reuseItems, `sourceSize` on all thumbnails,
   plain text format, no clip, filtering computed in the service in one assignment.
6. `//@ pragma` header: `ShellId triton`, `DefaultEnv QS_DROP_EXPENSIVE_FONTS=1`,
   `DefaultEnv QS_NO_RELOAD_POPUP=1` (dev), custom `QS_CRASHREPORT_URL`.
7. Profile before optimizing further: QML profiler if attachable (verify), `QSG_VISUALIZE=changes`
   for repaint auditing, GammaRay for binding storms. C++ plugin (caelestia-style) only if
   profiling shows QML-side config/service lookup cost — don't pre-pay the build complexity.

## 7. Uncertainties / things to verify on the target system

- Exact behavior/location of the Qt QML disk cache for file-tree-loaded configs in Quickshell;
  not documented. Verify compile-cache effectiveness empirically (startup timing cold vs warm).
- Whether `-qmljsdebugger` attachment works cleanly through the quickshell launcher in 0.3.0.
- `QsWindow.updatesEnabled` redraw semantics are broken-ish in 0.3.0 (fixed 0.3.1) — avoid
  depending on it or test carefully.
- `ScriptModel` had crash fixes in 0.3.1 — treat as risky in 0.3.0.
- Session-lock surfaces had several crash fixes in 0.3.1/0.3.2 (sleep/wake/DPMS, monitor plug).
  Since Triton includes a lock screen on 0.3.0, test DPMS+hotplug aggressively; this is the
  single riskiest area of the version pin. Consider documenting "upgrade to 0.3.2 if available"
  as a fallback.
- Icon theme cache persistence across reloads is undocumented.
- Idle CPU numbers in this report are qualitative; measure on target hardware.

## Sources

- Quickshell v0.3.0 usage guide, FAQ, advanced/pragmas, type docs (LazyLoader, Variants, etc.):
  <https://quickshell.org/docs/v0.3.0/guide> and subpages
- Quickshell changelog (0.2.0–0.3.2): <https://quickshell.org/changelog>
- Qt 6 performance guide: <https://doc.qt.io/qt-6/qtquick-performance.html>
- end-4/dots-hyprland (ii shell source inspection, commit @ 2026-11):
  <https://github.com/end-4/dots-hyprland>
- caelestia-dots/shell (source inspection): <https://github.com/caelestia-dots/shell>
