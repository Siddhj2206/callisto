pragma ComponentBehavior: Bound

import QtQuick
import ".."

// A workspace pill (BarStates `.ws`). Leaf component: the container decides
// which workspace is active and what a click does.
//
// Board CSS: height 40, min-width 40, radius 20, Jost 17px semibold.
// Active: min-width 56, solid primary fill, on-primary text.
// Inactive: bare number, on-surface-variant, no fill.

Rectangle {
    id: root

    required property int ws
    property bool active: false
    // When the compositor IPC is absent the pills render but are inert.
    property bool live: true

    signal clicked

    implicitHeight: 40
    implicitWidth: active ? 56 : 40
    radius: 20
    color: active ? Theme.primary : "transparent"
    // No animations here: the board specifies discrete states, and the tokens
    // define motion as springs, which QML tween animations cannot faithfully
    // reproduce. Width/color transitions arrive with the spring animation
    // primitives, not with hardcoded durations.

    Text {
        anchors.centerIn: parent
        text: root.ws
        color: root.active ? Theme.onprimary : Theme.onsurfacevariant
        font.family: "Jost SemiBold"
        font.pixelSize: 17
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.live
        cursorShape: root.live ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
