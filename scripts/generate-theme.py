#!/usr/bin/env python3
"""generate-theme.py — compile design/tokens.json into the shell's QML.

The design tokens are the single source of truth for every visual decision in
the Triton shell. It writes Theme.qml, Icons.qml and tokens/*.qml, each with a
header saying not to edit it. If a token is missing, this script fails loudly
rather than inventing a value.

Usage:
    scripts/generate-theme.py [--check]

    --check   verify the committed files are in sync with tokens.json
              (used by lint/CI); exits non-zero if regeneration would differ.
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TOKENS_PATH = REPO_ROOT / "design" / "tokens.json"
THEME_PATH = REPO_ROOT / "shell" / "triton" / "Theme.qml"
CODEPOINTS_PATH = REPO_ROOT / "design" / "fonts" / "symbols.codepoints"
ICONS_PATH = REPO_ROOT / "shell" / "triton" / "Icons.qml"

HEADER = """// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py
"""


def fail(msg: str) -> "SystemExit":
    return SystemExit(f"generate-theme: error: {msg}")


def require(obj: dict, key: str, ctx: str):
    if key not in obj:
        raise fail(f"missing required token '{key}' in {ctx}")
    return obj[key]


def strip_commentish(value):
    """Tokens sometimes carry units or notes ('#2458C8 (approximate)')."""
    if isinstance(value, str):
        return value.split(" ")[0]
    return value


UI_DIR = REPO_ROOT / "shell" / "triton" / "tokens"


def camel(name: str) -> str:
    """Material role name -> QML property (on_primary -> onprimary)."""
    prop = re.sub(r"_([a-z])", lambda m: m.group(1).upper(), name)
    return prop.lower() if re.match(r"on[A-Z]", prop) else prop


def singleton(imports: list, body: list) -> str:
    return "\n".join([HEADER, "pragma Singleton", *imports, "", "QtObject {", *body, "}", ""])


def theme(tokens: dict) -> str:
    """The shell-wide state beside the tokens: the user's palette, mode and motion."""
    layers = []
    for name, val in require(tokens, "state_layer", "root").items():
        prop = camel("state_" + name)
        layers.append(f"    readonly property real {prop}: {val}")
    return singleton(["import QtQuick"], [
        "    // How strongly a layer of ink shows over a control in each state.",
        *layers,
        "",
        "    // The theme engine writes the user's palette to tokens.json. ThemeSync",
        "    // hands it over here and tokens/Colors.qml reads it. It is kept so auto",
        "    // mode can resolve again at dawn and dusk, when the file does not change.",
        "    property var userTokens: null",
        '    property string activeMode: "dark"',
        "",
        "    // Follows the setting. tokens/Motion.qml shortens every fade when set.",
        "    property bool reduceMotion: false",
        "",
        '    // "auto" is light from 07:00 to 19:00 local time.',
        "    function resolveMode(mode) {",
        '        if (mode !== "auto")',
        "            return mode;",
        "        const hour = new Date().getHours();",
        '        return hour >= 7 && hour < 19 ? "light" : "dark";',
        "    }",
        "",
        "    function applyUserTokens(parsed) {",
        "        if (!parsed || !parsed.color)",
        "            return;",
        "        userTokens = parsed;",
        '        activeMode = resolveMode(parsed.active_mode || "dark");',
        "    }",
    ])


def ui_tokens(tokens: dict) -> dict:
    """Render the component-shell token singletons. Returns {path: text}."""
    ui = require(tokens, "ui", "root")
    shape = tokens["shape"]["wave"]
    density = '    readonly property bool board: Quickshell.env("CALLISTO_DENSITY") === "board"'

    metrics = [density, ""]
    for name, (compact, board) in ui["metrics"].items():
        value = compact if compact == board else f"board ? {board} : {compact}"
        metrics.append(f"    readonly property real {name}: {value}")
    metrics += ["", f'    readonly property string wavePath: "{shape["path"]}"']

    families = tokens["type"]["families"]
    roles = []
    for name, spec in ui["type"].items():
        if name.startswith("_"):
            continue
        family, weight, size, line = spec
        roles.append(
            f'        "{name}": {{ family: "{families[family]}", weight: {weight}, '
            f"size: board ? {size[1]} : {size[0]}, line: board ? {line[1]} : {line[0]} }},"
        )
    typography = [density, "", "    readonly property var roles: ({", *roles, "    })"]

    motion = ['    // Springs are [stiffness, damping ratio].']
    for name in ("spatial_fast", "spatial_default", "spatial_slow", "shake"):
        k, z = tokens["motion"][name]
        motion.append(f"    readonly property var {camel(name)}: [{k}, {z}]")
    motion.append("")
    motion.append("    property bool reduce: Theme.reduceMotion")
    fade = ui["fade"]
    for name in ("fast", "default", "slow"):
        key = "fade" + name.capitalize()
        motion.append(f'    readonly property int {key}: reduce ? {fade["reduced"]} : {fade[name]}')
    motion.append("")
    for name, val in ui["timing"].items():
        motion.append(f"    readonly property int {name}: {val}")

    colors = []
    for mode in ("dark", "light"):
        colors.append(f"    readonly property Scheme {mode}: Scheme {{")
        for name, val in tokens["color"][mode].items():
            v = strip_commentish(val)
            if re.fullmatch(r"#[0-9A-Fa-f]{6}", v):
                colors.append(f'        {camel(name)}: "{v.upper()}"')
        for name, val in ui["material"][mode].items():
            key = name if name == "ink" else name + "Alpha"
            colors.append(f'        {key}: "{val}"' if name == "ink" else f"        {key}: {val}")
        # Until the wallpaper has been looked at, assume the design's case.
        colors.append(f'        behind: "{"#000000" if mode == "dark" else "#FFFFFF"}"')
        colors.append("    }")
    colors += [
        "",
        '    readonly property Scheme current: Theme.activeMode === "light" ? light : dark',
        "",
        "    // The engine writes the user's palette to tokens.json; Theme parses it.",
        "    function load() {",
        "        const user = Theme.userTokens?.color;",
        "        if (!user)",
        "            return;",
        "        dark.assign(user.dark);",
        "        light.assign(user.light);",
        "    }",
        "",
        "    property Connections follow: Connections {",
        "        target: Theme",
        "        function onUserTokensChanged() { root.load(); }",
        "    }",
        "    Component.onCompleted: load()",
    ]
    colors = ["    id: root", "", *colors]

    scheme_names = [camel(n) for n, v in tokens["color"]["dark"].items()
                    if re.fullmatch(r"#[0-9A-Fa-f]{6}", strip_commentish(v))]
    scheme = [HEADER, "import QtQuick", "",
              "// One color scheme: the Material roles plus the materials derived from them.",
              "QtObject {"]
    scheme += [f"    property color {n}" for n in scheme_names]
    scheme += [
        "",
        "    property color ink",
        "    property real micaAlpha",
        "    property real glassAlpha",
        "    property real thickAlpha",
        "    property real veilAlpha",
        "    property real veilHiAlpha",
        "    property real highlightAlpha",
        "    property real hairlineAlpha",
        "    property real backdropAlpha",
        "",
        "    // Mica and Glass show the wallpaper only. This is its brightest color",
        "    // under the dark scheme, its darkest under the light one.",
        "    property color behind",
        '    // The "Solid" material setting: nothing is translucent.',
        "    property bool solid: false",
        "",
        "    readonly property color mica: Qt.alpha(surfaceContainerLow, solid ? 1 : legible(surfaceContainerLow, micaAlpha))",
        "    readonly property color glass: Qt.alpha(surfaceContainerHigh, solid ? 1 : legible(surfaceContainerHigh, glassAlpha))",
        "    // Thick sees the windows below, so its alpha holds over anything.",
        "    readonly property color thick: Qt.alpha(surfaceContainerHigh, solid ? 1 : thickAlpha)",
        "    readonly property color veil: Qt.alpha(ink, veilAlpha)",
        "    readonly property color veilHi: Qt.alpha(ink, veilHiAlpha)",
        '    readonly property color highlight: Qt.rgba(1, 1, 1, highlightAlpha)',
        "    readonly property color hairline: Qt.alpha(ink, hairlineAlpha)",
        "    // The blue-black laid over the whole screen behind modal surfaces.",
        "    readonly property color backdrop: Qt.rgba(0, 10 / 255, 30 / 255, backdropAlpha)",
        "",
        "    // The least opaque a material can be, from its designed alpha up, with",
        "    // secondary text on a veil still at 4.5:1 over what is behind it.",
        "    // scripts/check-contrast.py does the same sum.",
        "    function legible(fill, designed) {",
        "        const text = luminance(onsurfacevariant.r, onsurfacevariant.g, onsurfacevariant.b);",
        "        const mix = (a, b, t) => a * t + b * (1 - t);",
        "        for (let alpha = designed; alpha < 1; alpha += 0.01) {",
        "            const under = luminance(...[\"r\", \"g\", \"b\"].map(c => mix(ink[c], mix(fill[c], behind[c], alpha), veilAlpha)));",
        "            if ((Math.max(text, under) + 0.05) / (Math.min(text, under) + 0.05) >= 4.5)",
        "                return alpha;",
        "        }",
        "        return 1;",
        "    }",
        "",
        "    function luminance(r, g, b) {",
        "        const linear = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);",
        "        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);",
        "    }",
        "",
        "    function assign(roles) {",
        "        for (const key in roles) {",
        "            let prop = key.replace(/_([a-z])/g, (m, c) => c.toUpperCase());",
        "            if (/^on[A-Z]/.test(prop))",
        "                prop = prop.toLowerCase();",
        "            if (prop in this)",
        "                this[prop] = roles[key];",
        "        }",
        "    }",
        "}",
        "",
    ]

    return {
        UI_DIR / "Metrics.qml": singleton(["import Quickshell", "import QtQuick"], metrics),
        UI_DIR / "Typography.qml": singleton(["import Quickshell", "import QtQuick"], typography),
        UI_DIR / "Motion.qml": singleton(["import QtQuick", "import qs"], motion),
        UI_DIR / "Colors.qml": singleton(["import QtQuick", "import qs"], colors),
        UI_DIR / "Scheme.qml": "\n".join(scheme),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    tokens = json.loads(TOKENS_PATH.read_text())
    outputs = {THEME_PATH: theme(tokens), **ui_tokens(tokens)}

    # ---- Icons singleton ------------------------------------------------------
    # Material Symbols ligatures ("wifi" as literal text) depend on OpenType
    # liga/dlig shaping, which Qt does not reliably enable. Direct codepoints
    # always render — same as the Rust implementation. Generated from
    # design/fonts/symbols.codepoints, the subset manifest for TritonSymbols.
    if CODEPOINTS_PATH.exists():
        icon_lines = [
            HEADER,
            "pragma Singleton",
            "import QtQuick",
            "",
            "// Icon codepoints in the Triton Symbols font. Use as:",
            "//   text: Icons.wifi   font.family: \"Triton Symbols\"",
            "QtObject {",
        ]
        # JavaScript reserved words cannot be property identifiers in QML
        # object literals — one illegal name (e.g. "delete") invalidates the
        # entire singleton type, not just that property.
        RESERVED = {
            "break", "case", "catch", "class", "const", "continue", "debugger",
            "default", "delete", "do", "else", "enum", "export", "extends",
            "false", "finally", "for", "function", "if", "import", "in",
            "instanceof", "new", "null", "return", "super", "switch", "this",
            "throw", "true", "try", "typeof", "var", "void", "while", "with",
            "yield", "let", "static", "await",
            # strict-mode future reserved words — QML rejects them too
            "implements", "interface", "package", "private", "protected",
            "public",
        }
        count = 0
        for line in CODEPOINTS_PATH.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 2:
                continue
            name, cp = parts
            # snake_case -> camelCase. Underscores before digits disappear
            # entirely (battery_5_bar -> battery5Bar), letters capitalize.
            prop = re.sub(r"_([a-z0-9])", lambda m: m.group(1).upper() if m.group(1).isalpha() else m.group(1), name)
            if prop[0].isdigit():
                prop = "icon" + prop
            if prop in RESERVED:
                prop = prop + "Icon"
            icon_lines.append(f'    readonly property string {prop}: "\\u{cp}"')
            count += 1
        icon_lines += [
            "",
            "    // The speaker for a volume from 0 to 1.",
            "    function volume(level, muted) {",
            "        return muted ? volumeOff : level <= 0 ? volumeMute : level < 0.5 ? volumeDown : volumeUp;",
            "    }",
            "}",
            "",
        ]
        outputs[ICONS_PATH] = "\n".join(icon_lines)

    if args.check:
        stale = [p for p, text in outputs.items() if not p.exists() or p.read_text() != text]
        for path in stale:
            print(f"generate-theme: {path.relative_to(REPO_ROOT)} is out of sync", file=sys.stderr)
        if not stale:
            print("generate-theme: generated files are in sync")
        return 1 if stale else 0

    UI_DIR.mkdir(exist_ok=True)
    for path, text in outputs.items():
        path.write_text(text)
        print(f"generate-theme: wrote {path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
