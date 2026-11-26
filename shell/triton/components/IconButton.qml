pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Circular icon button (design board `.t-icon-btn`): a square the size of
// `size` with fully rounded corners at rest. Pressed/checked morphs toward a
// rounded square (radius 12 when size >= 32, per the boards). Sizes in use:
// 32, 40, 48 — pass exactly what the owning surface's board specifies.
//
// State layer: hover/press draw a translucent overlay in the content color,
// alphas from the state tokens — never hardcoded.

Rectangle {
    id: root

    required property string icon
    property bool fillIcon: false
    property bool checked: false
    property real size: 40
    property real iconSize: Math.round(size * 0.55)

    // Colors: default is the quiet variant — transparent fill, onsurface
    // content. Filled variants come from the caller via color/contentColor.
    property color fill: "transparent"
    property color contentColor: Theme.onsurface

    signal clicked

    width: size
    height: size
    radius: mouse.pressed || checked ? Math.min(12, size / 2) : size / 2
    color: root.fill

    TritonIcon {
        anchors.centerIn: parent
        glyph: root.icon
        fill: root.fillIcon
        size: root.iconSize
        color: root.contentColor
    }

    // State layer, in content color so it works on any fill.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.contentColor
        opacity: mouse.pressed ? Theme.statePress
               : mouse.containsMouse ? Theme.stateHover : 0
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
