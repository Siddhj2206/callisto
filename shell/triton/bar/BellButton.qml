pragma ComponentBehavior: Bound

import QtQuick
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

    Text {
        anchors.centerIn: parent
        text: "notifications"
        color: Theme.onsurface
        font.family: "Triton Symbols"
        font.pixelSize: 24
    }

    // Unread dot: 10px tertiary circle at the top-right (board `.bell u`).
    Rectangle {
        visible: root.hasUnread
        x: parent.width - width - 7 // board: right offset ~10px minus stroke overlap
        y: 9 - 2 // board: top 9px, minus stroke overlap
        width: 10
        height: 10
        radius: 5
        color: Theme.tertiary
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
