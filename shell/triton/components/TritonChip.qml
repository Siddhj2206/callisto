pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Filter chip (boards `.t-chip`): 36px tall, radius 10, 14px horizontal
// padding. Resting state is an outline ghost (1px outline stroke, onv text);
// the selected chip fills in secondary-container with its on-color and drops
// the stroke. `.on` styling can be tinted per context (launcher Commands chip
// uses tertiary-container) — pass tint colors then.

Rectangle {
    id: root

    property string text: ""
    property bool selected: false
    // Override for tinted selection states (launcher Commands chip).
    property color selectedFill: Theme.secondaryContainer
    property color selectedContent: Theme.onsecondarycontainer

    signal clicked

    height: 36
    width: Math.max(56, label.implicitWidth + 28)
    radius: 10
    color: root.selected ? root.selectedFill : "transparent"
    border.width: root.selected ? 0 : 1
    border.color: Theme.outline

    TritonText {
        id: label
        anchors.centerIn: parent
        text: root.text
        weight: TritonText.Weight.Medium
        font.pixelSize: 14
        color: root.selected ? root.selectedContent : Theme.onsurfacevariant
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
