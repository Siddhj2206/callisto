pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The shell slider (board `.sld`): 44px interactive height, 16px tracks.
// The active track is primary with asymmetric radii (8px outer, 2px at the
// handle), the remainder white/.2 the mirror image; the handle is a 4px
// full-height primary bar centered on the value.

Item {
    id: root

    property real value: 0.5 // 0..1
    signal moved(real v)

    height: 44

    // Inactive track.
    Rectangle {
        x: parent.width * root.value + 3
        y: 14
        width: parent.width * (1 - root.value) - 3
        height: 16
        radius: 8
        color: "#33FFFFFF" // white .2
    }
    // Active track.
    Rectangle {
        x: 0
        y: 14
        width: parent.width * root.value - 3
        height: 16
        radius: 8
        color: Theme.primary
    }
    // Handle.
    Rectangle {
        x: parent.width * root.value - width / 2
        width: 4
        height: 44
        radius: 2
        color: Theme.primary
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, mouse.x / width)));
        }
    }
}
