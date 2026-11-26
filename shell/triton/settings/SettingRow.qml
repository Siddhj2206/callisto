pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The canonical settings list row (.t-li): min-height 64, surface-container
// fill, radius progression handled by the parent list. Leading icon disc
// optional; title + supporting text; trailing content is caller-provided
// via the default alias (switch, slider, chips, chevron…).

Rectangle {
    id: root

    property string icon: ""
    property bool fillIcon: false
    property string title: ""
    property string supporting: ""
    default property alias trailing: trailingSlot.data

    width: parent ? parent.width : 400
    height: Math.max(64, contentCol.implicitHeight + 24)
    radius: 12
    color: Theme.surfaceContainer

    Row {
        x: 20
        height: parent.height
        spacing: 16

        Rectangle {
            visible: root.icon !== ""
            width: 40
            height: 40
            radius: 20
            color: Theme.secondaryContainer
            anchors.verticalCenter: parent.verticalCenter

            TritonIcon {
                anchors.centerIn: parent
                glyph: root.icon
                fill: root.fillIcon
                size: 22
                color: Theme.onsecondarycontainer
            }
        }

        Column {
            id: contentCol
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: root.width - 40 - (root.icon !== "" ? 56 : 0) - trailingSlot.width - 16

            TritonText {
                text: root.title
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 15
                color: Theme.onsurface
            }
            TritonText {
                visible: root.supporting !== ""
                text: root.supporting
                font.pixelSize: 13
                color: Theme.onsurfacevariant
                width: parent.width
                elide: Text.ElideRight
            }
        }
    }

    Row {
        id: trailingSlot
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
