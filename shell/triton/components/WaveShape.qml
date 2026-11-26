pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."

// The Triton wave as a badge shape: the 9-lobe identity path filled in a
// token color, optionally carrying a centered Material Symbols icon.
//
// The wave is identity only — launcher button, search badges, avatars, album
// art, OSD off-states (tokens.json wave usage). App and file icons never use
// it; those sit in plain circles.
//
// The path is authored in a 100x100 viewBox; this item draws it scaled to
// `size` with the transform origin at the center, exactly like the boards.

Item {
    id: root

    // Size of the whole badge, square.
    property real size: 40
    // Wave fill. Boards use primary, tertiary (commands/error states) and
    // error-container depending on context — the caller chooses the token.
    property color color: Theme.primary
    // Optional centered glyph. Empty string = bare wave.
    property string glyph: ""
    property color glyphColor: Theme.onprimary
    property real glyphSize: Math.round(root.size * 0.6)
    property bool fillGlyph: false

    width: root.size
    height: root.size

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            // The path is authored in a 100x100 viewBox; scaling the path
            // itself keeps ink inside the item (scaling the Shape would let
            // it paint past its bounds, clipped or not).
            PathSvg {
                path: Theme.wavePath
            }

            scale: Qt.size(root.size / 100, root.size / 100)
        }
    }

    TritonIcon {
        visible: root.glyph !== ""
        anchors.centerIn: parent
        glyph: root.glyph
        fill: root.fillGlyph
        size: root.glyphSize
        color: root.glyphColor
    }
}
