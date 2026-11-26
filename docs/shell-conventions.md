# Triton shell QML conventions

Rules every component in `shell/triton/` must follow. Read this before writing
any QML. Violations of these rules are bugs.

## Environment

- **Quickshell 0.3.0** (Debian trixie-backports pin) — do not use APIs from
  newer versions. Host/dev machines may have 0.3.2; the target is 0.3.0.
- **Qt 6 / QML**, Hyprland 0.55 as the compositor on the ISO.
- Run locally with `qs -p shell/triton` inside the test harness.

## Non-negotiables

1. **`pragma ComponentBehavior: Bound`** as the first line of every file.
2. **Never hardcode colors, radii, spacing, sizes, fonts, or motion.** All of
   it comes from `Theme` (the singleton generated from `design/tokens.json` —
   never edit `Theme.qml` by hand; regenerate with `scripts/generate-theme.py`).
3. **`Theme` color properties use lowercase for the Material `on_*` tokens**:
   `onprimary`, `onprimarycontainer`, `onsurface`, `onsurfacevariant` — camelCase
   `onPrimary` parses as a signal handler in QML and fails at load time.
   Non-`on*` tokens are available in both camelCase and snake_case.
4. **The design boards in `references/*.dc.html` are the spec.** They are HTML:
   the CSS and markup inside them contain the exact pixel values, colors,
   component states, and caption explanations. Read the board for your
   component before writing anything; implement what it says, not a guess.
5. **No `new Date()` in bindings** — use `SystemClock` with the right precision.
6. **No polling.** Quickshell's Hyprland/PipeWire/UPower integration is
   event-driven; bind directly.
7. **Pipewire objects need `PwObjectTracker`** before their properties are valid.
8. **`Quickshell.execDetached()` for launching apps** — a tracked `Process` dies
   when the shell reloads.
9. **Delegate state upward**: leaf components (a pill, a button) receive state
   as required properties and never query services themselves; container
   components own service bindings. Keeps leaves testable and reusable.
10. **Degrade cleanly**: no battery in a VM means no battery readout; no audio
    sink means no volume control. Never render placeholder garbage.

## Theme quick reference (from `design/tokens.json`)

- Materials: `Theme.glassBg` (#282A2F @ 70%) for bar islands/popovers,
  `Theme.thickGlassBg` (@ 88%) for the launcher, `Theme.micaBg` for strips.
  Never stack glass on glass.
- `Theme.veil` (white @ 10%): fill for controls sitting ON glass. `veilBright` @ 16%.
- Radii: `radiusXs/Sm/Md/Lg/Xl/Full` = 8/12/16/20/28/9999.
- Spacing: `Theme.space[n]` indexes [4,8,12,16,20,24,32,40,48,56].
- Type: display font is `Jost` (big numbers, headings), UI font fallback
  `"Google Sans Flex"` then `Inter`; icons are `Triton Symbols` (Material
  Symbols Rounded subset, ligature names like "wifi", "volume_up").
- Sizes: `barHeight` = 56; controls s/m/l/xl = 32/40/48/56.
- Identity: `Theme.wavePath` (the 9-lobe wave, 100x100 viewBox) — identity
  elements only, never generic icons.

## Repo layout

```
shell/triton/
├── shell.qml          # entry point: thin, instantiates surfaces per screen
├── Theme.qml          # GENERATED — do not edit
├── bar/               # the top bar (islands, workspaces, clock, status)
├── launcher/          # native Triton launcher (replaces fuzzel later)
├── osd/               # volume/brightness overlays
├── quicksettings/     # control center popover
├── lock/              # lock screen
├── notifications/     # notification popups + center
├── services/          # non-visual singletons (audio, network, state)
└── components/        # shared visual primitives
```
# QML layout rules for the Triton shell

Hard-won, verified against the headless sway harness. Violating these is how
"everything is everywhere" happens. These rules apply to ALL shell QML code.

## The invariant

**Children of a Row are never implicitly centered vertically. In Triton,
content rows follow one pattern:**

```
Row {
    anchors.centerIn: parent        // the ROW centers in its container
    height: parent.height           // and fills the container's height
    spacing: ...
    // children: TritonIcon / TritonText / fixed-size controls only
}
```

Because every atom (`TritonIcon`, `TritonText`) centers its own glyphs within
its own box, a row of them at full container height is aligned by construction.
No per-child `anchors.verticalCenter` arithmetic, no baseline math.

## Why not alternatives

- `Row` positions children at y=0. Different-height children end up top-aligned.
- `anchors.verticalCenter` per child works but is easy to forget and produces
  subtle 1-2px misalignment when glyph metrics differ.
- Text baseline alignment (`alignBaseline`) is fragile across mixed fonts
  (Jost vs icons) — the boards never ask for it except clock+date, which is
  hand-tuned in Clock.qml only.

## The atoms

- `TritonIcon` — square item of `size`, glyph centered inside. Default 22px.
- `TritonText` — text with correct family resolution (`family`/`weight` enums).
  Set `boxHeight` to center glyphs inside a fixed-height box.

Anything interactive is a fixed-height shape (pill/circle/rounded-square) whose
radius is half its height unless the board says otherwise — see
docs/research/design-board-map.md for exact sizes.

## Other verified facts

- Fonts resolve by full family+weight names ("Jost SemiBold"), NOT weight
  matching. Static instances only.
- Icons are Unicode codepoints via the `Icons` singleton. Ligature names do
  NOT shape in Qt.
- Icons/Theme singletons must BOTH be registered in shell/triton/qmldir.
- `test-shell.sh` copies fonts from design/fonts into shell/triton/fonts each run.
