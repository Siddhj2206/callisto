pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import ".."

// The notification bell (BarStates `.bell`): a 44px veil circle with the
// "notifications" icon. The veil is the fill for controls sitting on Glass —
// a solid container would read as a hole (Materials board).
//
// The tertiary notification dot (board markup `<u>`) appears only when there
// are unread notifications; notification service integration is deferred, so
// the dot is bound but currently always hidden.

Rectangle {
    id: root

    signal clicked

    property bool hasUnread: false

    width: 44
    height: 44
    radius: 22 // half the control height; radiusFull reads as a circle here
    color: Theme.veil

    TritonIcon {
        anchors.centerIn: parent
        glyph: Icons.notifications
        size: 24
        color: Theme.onsurface
    }

    // Unread dot (board `.bell u`): 10px tertiary circle at top 9 / right 10,
    // ringed by a 2px surface-colored stroke (the board's box-shadow) so it
    // reads against both the veil and whatever is behind the glass.
    Rectangle {
        visible: root.hasUnread
        x: parent.width - width - 10 - 2 // right: 10px inside the stroke
        y: 9 - 2                         // top: 9px inside the stroke
        width: 14
        height: 14
        radius: 7
        color: "#3a3c41" // board box-shadow ring color

        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 5
            color: Theme.tertiary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
