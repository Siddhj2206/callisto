pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The icon atom. A Material Symbols glyph from the bundled Triton Symbols
// subset, referenced by codepoint (Icons singleton) — never by ligature name,
// which Qt does not reliably shape.
//
// This item is an exact square of `size` and the glyph is centered inside it,
// so dropping it into a row of other square items aligns everything without
// any further work. `fill` selects the filled variant of the font.

Text {
    id: root

    // Icons.<name> — pass the codepoint string.
    required property string glyph
    property bool fill: false

    // Default matches the most common board size; callers override.
    property real size: 22

    width: root.size
    height: root.size

    text: root.glyph
    font.family: root.fill ? "Triton Symbols Filled" : "Triton Symbols"
    font.pixelSize: root.size
    color: Theme.onsurface
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
