pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// A rectangle with per-corner radii. Qt's Rectangle only rounds uniformly,
// but the shell's cards are asymmetric by design (notification cards round
// 24px except the bottom-left at 10px; center items 20px except bottom-left
// at 8px). Shape path with manual arcs — cheap, exact, one draw call.

Shape {
    id: root

    // [topLeft, topRight, bottomRight, bottomLeft]
    property var radii: [0, 0, 0, 0]
    property color color: "transparent"

    antialiasing: true

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"

        PathMove {
            x: root.radii[0]
            y: 0
        }
        PathLine { x: root.width - root.radii[1]; y: 0 }
        PathArc {
            x: root.width
            y: root.radii[1]
            radiusX: root.radii[1]
            radiusY: root.radii[1]
        }
        PathLine { x: root.width; y: root.height - root.radii[2] }
        PathArc {
            x: root.width - root.radii[2]
            y: root.height
            radiusX: root.radii[2]
            radiusY: root.radii[2]
        }
        PathLine { x: root.radii[3]; y: root.height }
        PathArc {
            x: 0
            y: root.height - root.radii[3]
            radiusX: root.radii[3]
            radiusY: root.radii[3]
        }
        PathLine { x: 0; y: root.radii[0] }
        PathArc {
            x: root.radii[0]
            y: 0
            radiusX: root.radii[0]
            radiusY: root.radii[0]
        }
    }
}
