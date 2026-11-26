pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The shell switch (board `.t-switch`): 52x32, outline ring at rest with a
// 16px outline dot; on goes primary with a 24px on-primary dot carrying a
// check glyph. The thumb grows and crosses — that morph is the state change.

Rectangle {
    id: root

    property bool on: false
    signal toggled(bool v)

    width: 52
    height: 32
    radius: 16
    color: root.on ? Theme.primary : Theme.surfaceContainerHighest
    border.width: 2
    border.color: root.on ? Theme.primary : Theme.outline

    Rectangle {
        x: root.on ? 22 : 6
        y: root.on ? 2 : 6
        width: root.on ? 24 : 16
        height: root.on ? 24 : 16
        radius: width / 2
        color: root.on ? Theme.onprimary : Theme.outline

        Behavior on x { NumberAnimation { duration: 120 } }
        Behavior on width { NumberAnimation { duration: 120 } }
        Behavior on height { NumberAnimation { duration: 120 } }
        Behavior on y { NumberAnimation { duration: 120 } }

        TritonIcon {
            visible: root.on
            anchors.centerIn: parent
            glyph: Icons.check
            fill: true
            size: 16
            color: Theme.primary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.on)
    }
}
