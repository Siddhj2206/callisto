pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A floating Glass island (BarStates `.isl.t-glass`): 56px tall, fully
// rounded, glass fill. Children are laid out in a row with the board's
// internal rhythm: 6px edge padding, 4px gaps.
//
// Sizes from the board CSS:
//   height 56 = Theme.barHeight, radius 28 = Theme.radiusFloating,
//   gap 4 = Theme.space[0].
//   The 6px horizontal padding is not on the spacing scale; the board CSS
//   specifies it directly (`.isl{padding:0 6px}`), so it is derived here as
//   a literal with this note.
//
// The blur behind the glass (glassBlur) is the compositor's job — Hyprland
// blur applies to the layer surface; the fill is the pre-composited
// Theme.glassBg.

Rectangle {
    id: root

    default property alias content: row.children

    implicitWidth: row.implicitWidth + edgePadding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radiusFloating
    color: Theme.glassBg

    readonly property real edgePadding: 6 // board: .isl padding 0 6px

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space[0]
    }
}
