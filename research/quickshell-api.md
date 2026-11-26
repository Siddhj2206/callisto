# Quickshell API research

**Version reality check (important):** Debian trixie-backports actually ships **quickshell 0.3.0** (`0.3.0-1~bpo13+1`, per sources.debian.org API), not 0.2.x. Current upstream latest is 0.3.2. Docs site: `https://quickshell.outfoxxed.me` — per-version URLs of the form `/docs/v0.2.0/types/...`, `/docs/v0.3.0/types/...`. 0.2.x-era answers are given for every question, with 0.3.0 deltas flagged at the end of each section. For a shell targeting trixie-backports, the 0.3.0 docs are the correct target; 0.2.x notes are kept because many examples/shells are written against them and nothing described below was removed in 0.3.x.

---

## 1. Input region / click-through for layer surfaces

**Yes — there is a `mask` property on `QsWindow` (the base class of `PanelWindow`/`PopupWindow`/`FloatingWindow`), not on `WlrLayershell`.**

Doc: https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell/QsWindow#mask

```
mask : Region   // "The clickthrough mask. Defaults to null."
```

`Region` is a real type in the core `Quickshell` module: https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell/Region

- `item: Item` — geometry taken from an item (overrides x/y/width/height)
- `x, y, width, height: int`
- `regions: list<Region>` (default, readonly) — nested sub-regions
- `shape: RegionShape` — `Rect` default (enum: Rect/Ellipse/…)
- `intersection: Intersection` — default `Combine`; other modes `Xor`, `Subtract`, `Union`… control how the region composes with its parent. If the root mask's intersection is `Combine` the region is used as-is; otherwise it is applied on top of the (implicit full-window) window region. `Xor` inverts.

Verbatim from the docs:

```qml
ShellWindow {
  // The mask region is set to `rect`, meaning only `rect` is clickable.
  // All other clicks pass through the window to ones behind it.
  mask: Region { item: rect }

  Rectangle {
    id: rect
    anchors.centerIn: parent
    width: 100
    height: 100
  }
}
```

```qml
ShellWindow {
  // inverted mask: clicks inside `rect` pass through
  mask: Region { item: rect; intersection: Intersection.Xor }
  ...
}
```

Nested regions example (verbatim):

```qml
Region {
  width: 100; height: 100;

  Region {
    x: 50; y: 50;
    width: 50; height: 50;
    intersection: Intersection.Subtract
  }
}
```

Notes:
- The mask **only affects input**, not rendering. Transparency still needs a transparent window `color` and appropriate content.
- `mask: null` (default) = whole window receives input, even fully transparent pixels. A common pattern for click-through-everything-but-content is `mask: Region { item: someItem }` or combining several regions; for "never interactive", dux-shell uses `mask: Region { item: Item {} }` (a zero-size region ⇒ nothing clickable).
- Region updates: `Region` has a `changed()` signal you can emit manually "in cases the region does not update automatically" (e.g. binding loops / non-reactive geometry).
- Common gotcha: when you bind `mask` to an `item` whose visibility changes, geometry tracks automatically, but shells frequently re-bind `mask` between `null` and a region when a panel opens/closes. E.g. dux-shell `DBarWindow.qml`:

```qml
mask: Region {
    item: barWindow.clickThrough || (isIsland && !body.islandBandInteractive) ? null : body.inputMaskItem
}
```

### How real shells do click-off-to-dismiss vs click-through

**caelestia (caelestia-dots/shell)** uses both techniques in its fullscreen `drawers` window (`modules/drawers/ContentWindow.qml`, anchors all four edges):

```qml
mask: hasFullscreen ? emptyRegion : regions
// `regions` is a Region with intersection: Intersection.Xor nested child regions,
// one per panel: the Xor'd outer rect covers the whole screen, child Regions
// re-add the panel/bar areas as clickable.
```

Key pattern from caelestia's `modules/drawers/Regions.qml`: outer region sized to the window with `intersection: Intersection.Xor` — i.e. the *whole window is click-through EXCEPT the carved-out child regions* (bar, panel areas). Clicks outside panels therefore fall through to desktop windows **within the mask**, while dismissal is handled by:

```qml
HyprlandFocusGrab {
    id: focusGrab
    active: screenState.launcher || screenState.session || screenState.sidebar || ...
    windows: [root]
    onCleared: {
        root.screenState.launcher = false;
        root.screenState.session = false;
        ...
    }
}
```

So: **click-through transparency = `mask` with `Intersection.Xor` carving; click-off-to-dismiss scrim = `HyprlandFocusGrab` on Hyprland**. The scrim visual itself is just a fullscreen rectangle whose opacity is bound to panel state (`StyledRect { anchors.fill: parent; opacity: screenState.session ? 0.5 : 0; color: scrim }`) — but because the mask passes clicks through outside panel areas, the grab's `cleared` signal is what detects "clicked outside". On non-Hyprland compositors the fallback is a fullscreen `MouseArea` behind the content inside the mask region that sets `visible: false` on click (that's what most generic shells do).

**end-4 / other shells:** same two idioms: either (a) a fullscreen window whose scrim `MouseArea` covers the whole input region and closes the panel `onClicked`, with the panel content being a child that eats its own clicks; or (b) focus grab + XOR region. Simplest portable pattern:

```qml
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // no mask at all -> whole window receives input while open;
    // close on click anywhere outside panel content:
    MouseArea {
        anchors.fill: parent
        onClicked: closeMe()
        // scrim color
        Rectangle { anchors.fill: parent; color: "#80000000" }
        // panel content must be a child AFTER the MouseArea (or use z) and
        // contain its own MouseArea to absorb clicks
    }
}
```

and destroy/hide the window when closed so it stops eating input.

*0.3.x delta:* unchanged. 0.3.0 added per-corner radius to `Region` and `RegionShape`/`Intersection` are unchanged.

---

## 2. DesktopEntry / app scanning

**Yes, first-class, in the core module.** Types (v0.2.0):

- `DesktopEntries` — **singleton**, `import Quickshell`. https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell/DesktopEntries
  - `applications: ObjectModel<DesktopEntry>` readonly — "All desktop entries of type Application that are not Hidden or NoDisplay."
  - `byId(id): DesktopEntry` — exact match, includes NoDisplay entries, may return null
  - `heuristicLookup(name): DesktopEntry` — fuzzy-ish lookup "will try to guess - potentially incorrectly", may return null. Good for matching running toplevels to entries.
- `DesktopEntry` (uncreatable). https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell/DesktopEntry
  - Properties (all readonly): `id`, `name`, `genericName`, `comment`, `icon` (icon **name**, may be empty), `execString` (raw `Exec`, warning: cannot be run reliably), `command: list<string>` (parsed Exec — runnable), `workingDirectory`, `runInTerminal`, `noDisplay`, `categories: list<string>`, `keywords: list<string>`, `actions: list<DesktopAction>`, `startupClass` (0.2.0 docs) / `startupWmClass` (changelog mentions `DesktopEntry.startupWmClass` added in 0.2.0 — the doc page lists `startupClass`; treat both as the WM_CLASS matcher).
  - `execute(): void` — runs the app. "Currently ignores runInTerminal and field codes." Equivalent verbatim:

    ```qml
    Quickshell.execDetached({
      command: desktopEntry.command,
      workingDirectory: desktopEntry.workingDirectory,
    });
    ```

- `DesktopAction` — jump-list style actions of the entry.

**Filtering/searching:** there is no built-in search model; shells iterate `DesktopEntries.applications.values` and filter/sort in JS. Iteration idiom (ObjectModel exposes `.values` as a JS array).

Real usage — caelestia launcher, `modules/launcher/services/Apps.qml` (verbatim):

```qml
function launch(entry: DesktopEntry): void {
    appDb.incrementFrequency(entry.id);

    if (entry.runInTerminal)
        Quickshell.execDetached({
            command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
            workingDirectory: entry.workingDirectory
        });
    else
        entry.execute();
}
```

```qml
entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
```

and the delegate (`modules/launcher/items/AppItem.qml`, verbatim):

```qml
IconImage {
    asynchronous: true
    source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
    implicitSize: parent.height * 0.8
}
```

*0.2.1 delta:* desktop entry changes are tracked in real time (the model updates live). *0.3.0 delta:* fixed escape sequence handling in desktop entries; API unchanged.

---

## 3. Session lock

**Yes — ext-session-lock-v1, in `Quickshell.Wayland` since before 0.2.0.**

- `WlSessionLock` — https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Wayland/WlSessionLock
  - `locked: bool` — set true to lock, false to unlock. "Only one WlSessionLock may be locked at a time."
  - `secure: bool` readonly — true once compositor confirms all screens are covered
  - `surface: Component` (default property) — must create a `WlSessionLockSurface`; one instance per screen.
- `WlSessionLockSurface` — https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Wayland/WlSessionLockSurface
  - `screen: ShellScreen` readonly, `color`, `width`/`height` readonly, `contentItem`, `visible` readonly. Note: sized by compositor; put content in a child item.

Verbatim doc example:

```qml
WlSessionLock {
  id: lock

  WlSessionLockSurface {
    Button {
      text: "unlock me"
      onClicked: lock.locked = false
    }
  }
}

// ...
lock.locked = true
```

Warning verbatim: "If the WlSessionLock is destroyed or quickshell exits without setting `locked` to false, conformant compositors will leave the screen locked and painted with a solid color... The lock dying will not expose your session, but it will render it inoperable." Real locks therefore keep the `WlSessionLock` object alive outside the content tree and authenticate with `Quickshell.Services.Pam` (`PamContext`) before setting `locked = false`. Transparent lock surfaces "behave weirdly ... most compositors will ignore an attempt to do so".

*0.3.x delta:* many lock crash fixes; `ScreencopyView` works on lock surfaces in 0.3.1+. API identical.

---

## 4. Hyprland integration

`import Quickshell.Hyprland` — module listing (v0.2.0): https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Hyprland

Types: `GlobalShortcut`, `Hyprland` (singleton), `HyprlandEvent`, `HyprlandFocusGrab`, `HyprlandMonitor`, `HyprlandToplevel`, `HyprlandWindow` (attached object), `HyprlandWorkspace`.

**`Hyprland` singleton** — https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Hyprland/Hyprland
- readonly: `workspaces: ObjectModel<HyprlandWorkspace>` (sorted by id, named/negative ids first), `monitors`, `toplevels: ObjectModel<Toplevel>`, `focusedWorkspace`, `focusedMonitor`, `activeToplevel` (may be null), `requestSocketPath`, `eventSocketPath`
- `dispatch(request: string)` — executes any hyprland dispatcher, e.g. `Hyprland.dispatch("workspace 2")`, `Hyprland.dispatch("focuswindow address:0x...")`
- `monitorFor(screen)`, `refreshMonitors()`, `refreshToplevels()`, `refreshWorkspaces()`
- signal `rawEvent(HyprlandEvent)` — every socket2 event; `event.name`, `event.data` (parse with `HyprlandEvent`/`rawEvent`).

**`HyprlandWorkspace`**: `id`, `name`, `active`, `focused`, `urgent`, `monitor`, `toplevels`, `hasFullscreen` (0.3.x; check 0.2), `lastIpcObject` (raw JSON, requires refresh), `activate()` — equivalent to `dispatch("workspace ${name}")` (handles named/special workspaces correctly since 0.2.0).

**Window switcher / overview building blocks:**
- Generic (any compositor with ext-foreign-toplevel): `ToplevelManager` singleton in `Quickshell.Wayland` — `ToplevelManager.toplevels: ObjectModel<Toplevel>`. `Toplevel` (https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Wayland/Toplevel): `title`, `appId`, `activated` readonly, `fullscreen`/`maximized`/`minimized` (settable requests), `screens`, `parent`; functions `activate()`, `close()`, `fullscreenOn(screen)`, `setRectangle(window, rect)` (minimize-hint), `unsetRectangle()`; signal `closed()`.
- `ScreencopyView` (`Quickshell.Wayland`) — live capture of a screen/toplevel for thumbnails in an overview.
- Hyprland-specific: `HyprlandToplevel` adds `lastIpcObject` (address, workspace, fullscreen state, floating, etc.) and `Hyprland.activeToplevel`; activation via `Toplevel.activate()` or `Hyprland.dispatch("focuswindow ...")`.

**`HyprlandFocusGrab`** — https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Hyprland/HyprlandFocusGrab. Implements `hyprland_focus_grab_v1` (hyprland-specific!). `active: bool`, `windows: list<QtObject>` whitelist, signal `cleared()`. Verbatim doc example:

```qml
ShellRoot {
  FloatingWindow {
    id: window

    Button {
      anchors.centerIn: parent
      text: grab.active ? "Remove exclusive focus" : "Take exclusive focus"
      onClicked: grab.active = !grab.active
    }

    HyprlandFocusGrab {
      id: grab
      windows: [ window ]
    }
  }
}
```

This is THE click-off-dismiss mechanism on Hyprland (see §1).

**`GlobalShortcut`** — hyprland global shortcuts protocol; `name` (matches bind in hyprland config), `onPressed`/`onReleased`. Requires the keybind to exist in hyprland.conf (`bind = ..., global, quickshell:name`). **This is hyprland-only** — no compositor-portable shortcut API exists in 0.2.x.

**`HyprlandWindow`** — attached object for windows with hyprland-specific props.

*0.3.x delta:* added lua config support in the Hyprland module, generic `Quickshell.WindowManager` module (ext-workspace based) for compositor-agnostic workspaces, and 0.3.2 supports Hyprland's new workspace address format. Core APIs above unchanged.

---

## 5. Services matrix (0.2.x)

| Feature | Module (0.2.x) | Status |
|---|---|---|
| SystemTray | `Quickshell.Services.SystemTray` — `SystemTray` singleton, `SystemTrayItem` (with `icon`, `menu`/`DBusMenuItem`, `activate()`/`secondaryActivate()`/`scroll()`), plus `Quickshell.DBusMenu` types (`DBusMenuItem`, `QsMenuOpener`) | first-class |
| MPRIS | `Quickshell.Services.Mpris` — `Mpris` singleton (`players: ObjectModel<MprisPlayer>`), `MprisPlayer` (`trackTitle`, `trackArtist`, `position`, `length`, `playbackState`, `play()/pause()/next()/previous()`, `positionChanged` signal…) | first-class |
| Bluetooth | `Quickshell.Bluetooth` — **`added in 0.2.0`** (not in 0.1!). `Bluetooth` singleton, `BluetoothAdapter` (`enabled` settable, `state`, `discovering`), `BluetoothDevice` (`name`, `address`, `connected`, `paired`, `battery`…), enums `BluetoothAdapterState`, `BluetoothDeviceState`. Pairing is unauthenticated-only in 0.2.x | first-class since 0.2.0 |
| UPower | `Quickshell.Services.UPower` — `UPower` singleton (`displayDevice`, `onBattery`), `UPowerDevice` (`percentage`, `state`, `timeToEmpty`…) | first-class |
| Pipewire/volume | `Quickshell.Services.Pipewire` — `Pipewire` singleton (`defaultAudioSink`, `defaultAudioSource`), `PwNode` (`volume`/`muted` **settable**, `audio`), `PwNodeLinkTracker` | first-class |
| Notifications | `Quickshell.Services.Notifications` — implement your own daemon: `NotificationServer` (`onNotification`), `Notification` (`summary`, `body`, `appName`, `appIcon`, `image`, `actions`, `expireTimeout`, `close()`…) | first-class |
| NetworkManager | **NOT present in 0.2.x** — manual dbus/`nmcli` via `Process` required. Added in **0.3.0** as `Quickshell.Networking` (wifi scan/connect, `Networking` singleton). **Since trixie-backports is 0.3.0, it IS available.** | manual in 0.2.x / first-class in 0.3.0 |
| Brightness/backlight | **No service in any version through 0.3.x** — shells use `Process` + `brightnessctl` or read/write `/sys/class/backlight` directly (caelestia vendored a tiny `brightness` helper binary; dux-shell uses sysfs + UPower+dbus) | manual |
| Idle inhibit / polkit / idle timeouts | not in 0.2.x; **added in 0.3.0** (`Quickshell.Services.Polkit`, wayland idle-inhibit/idle-timeout objects in `Quickshell.Wayland`) | 0.3.0 only |

---

## 6. Process / execDetached

`Process` — `import Quickshell.Io`. https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Io/Process

Key props: `command: list<string>` (each arg separate — **no shell**; use `["sh", "-c", "..."]` if needed), `running: bool` (set false → SIGTERM; killed when quickshell dies/reloads unless detached), `workingDirectory`, `environment: object`, `clearEnvironment: bool`, `stdinEnabled`, `stdout`/`stderr: DataStreamParser` (`StdioCollector`, `SplitParser`), `processId` readonly. Functions: `exec(context)` — reconfigure+start in one call; `startDetached()`; `signal(int)`; `write(data)`. Signals: `exited(exitCode, exitStatus)`, `started()`.

`exec(context)` accepts either a plain list or object `{command, environment, clearEnvironment, workingDirectory}`.

**`Quickshell.execDetached(context)`** — exists, **added in 0.2.0** (so: not available in 0.1.0). https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell/Quickshell#execDetached

Signature: `execDetached(context)` where context is either a list of args or `{command, environment, clearEnvironment, workingDirectory}`. Equivalent to `Process.startDetached()`. Verbatim usage from `DesktopEntry` docs:

```qml
Quickshell.execDetached({
  command: desktopEntry.command,
  workingDirectory: desktopEntry.workingDirectory,
});
```

Note from 0.2.0 changelog: "stdout/stderr of detached processes and executed desktop entries are now hidden by default."

---

## 7. Icons

Two correct mechanisms in 0.2.x:

**a) `Quickshell.iconPath(icon)`** — returns a string usable directly as `Image.source`/`IconImage.source`. Overloads:
- `iconPath(icon)` — missing icon renders a "missing texture" image
- `iconPath(icon, check: bool)` — `check: true` returns **empty string** if icon missing
- `iconPath(icon, fallback: string)` — fallback icon name

Theme selection: icons come from the qt platform theme by default; override with `//@ pragma IconTheme <name>` at top of root qml or `QS_ICON_THEME` env var.

**b) `image://icon/<name>` image provider** — exists and is used in shells, e.g. dux-shell `Paths.qml`: `return "image://icon/" + target;` — note however that `image://icon/` resolves theme names only; dux passes already-resolved absolute paths through `Quickshell.iconPath`/`image://icon` inconsistently. The *documented* API is `Quickshell.iconPath`; `image://icon/` is a QQuickImageProvider registered by quickshell and is stable in practice (used by end-4 and dux heavily).

**Display widget:** `IconImage` — `import Quickshell.Widgets`. https://quickshell.outfoxxed.me/docs/v0.2.0/types/Quickshell.Widgets/IconImage — specialized `Image` for icons: `source` (string url), `implicitSize`, `asynchronous`, `mipmap`, `backer` (access underlying Image), `actualSize` readonly. Typical:

```qml
IconImage {
    asynchronous: true
    source: Quickshell.iconPath(entry.icon, "image-missing")
    implicitSize: 24
}
```

Absolute file paths and `file://` urls can be passed straight to `Image`/`IconImage` too.

*0.3.0 delta:* `Quickshell.hasThemeIcon(icon): bool` added ("detect if an icon is from the system icon theme").

---

## Quick version-flag summary (what trixie-backports 0.3.0 has that pure 0.2.x doesn't)

- `Quickshell.Networking` module (NetworkManager) — **0.3.0+ only**
- `Quickshell.Services.Polkit`, wayland idle-inhibit/idle-timeout, popup-window focus grabbing, ext-workspace `Quickshell.WindowManager`, background blur effect — 0.3.0+ only
- `Quickshell.hasVersion(major, minor[, features])`, `hasQtVersion`, `hasThemeIcon` — 0.3.0+; usable in preprocessor gates: `//@ if hasVersion(0, 3)` … `//@ endif`
- Everything in §§1–4, 6–7 exists in both 0.2.x and 0.3.x unchanged.
- `Quickshell.execDetached` — **0.2.0+** (absent in 0.1.0).
- Bluetooth module — **0.2.0+** (absent in 0.1.0).
