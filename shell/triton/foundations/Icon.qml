import QtQuick
import qs
import qs.tokens

// A Material Symbols glyph (from the Icons singleton) in a square box.
Text {
    id: root

    property string glyph: ""
    property string size: "md" // "sm" | "md" | "lg"
    property bool fill: false
    property string tone: "onsurface"

    readonly property real pixels: size === "sm" ? Metrics.iconSm : size === "lg" ? Metrics.iconLg : Metrics.iconMd

    width: pixels
    height: pixels
    text: glyph
    font.family: fill ? "Triton Symbols Filled" : "Triton Symbols"
    font.pixelSize: pixels
    // Default distance fields smear fine cut-outs (the tick in check_circle).
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    color: Theming.of(root)[tone]
    Behavior on color { ColorFade {} }
}
