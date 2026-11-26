pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import ".."

// A floating Glass island (BarStates `.isl.t-glass`): 56px tall, fully
// rounded, glass fill. Children lay out in a ContentRow, so everything inside
// is vertically centered by construction.
//
// Board CSS: height 56 = Theme.barHeight, radius 28 = Theme.radiusFloating,
// gap 4 = Theme.space[0], horizontal padding 6px (`.isl{padding:0 6px}` — not
// on the spacing scale, kept as a documented literal).
//
// The blur behind the glass is the compositor's job (Hyprland blur on the
// layer surface); the fill is the pre-composited Theme.glassBg.

Rectangle {
    id: root

    default property alias content: row.children

    implicitWidth: row.implicitWidth + edgePadding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radiusFloating
    color: Theme.glassBg

    readonly property real edgePadding: 6 // board: .isl padding 0 6px

    ContentRow {
        id: row
        spacing: Theme.space[0]
    }
}
