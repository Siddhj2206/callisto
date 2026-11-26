pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."

// A ring that follows the wave silhouette: the board's countdown ring (and
// the wavy progress tracks) trace the 9-lobe path rather than a circle.
// The stroke follows the outline exactly.

Shape {
    id: root

    property real size: 34
    property real thickness: 3
    property color color: Theme.tertiary
    // Dimmer track color behind the value arc, white/.25 in the board.
    property color trackColor: "#40FFFFFF"

    width: root.size
    height: root.size
    antialiasing: true

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.color
        strokeWidth: root.thickness // ShapePath scaling includes stroke width
        capStyle: ShapePath.RoundCap
        scale: Qt.size(root.size / 100, root.size / 100)

        PathSvg {
            path: Theme.wavePath
        }
    }
}
