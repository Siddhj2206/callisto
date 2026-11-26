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

    // While dragging, the slider shows the pointer position even if the
    // backend hasn't caught up — controlled-only snapping mid-drag reads as
    // broken. On release the bound value resumes ownership.
    property bool dragging: false
    property real dragValue: 0.5
    readonly property real shown: dragging ? dragValue : value

    // Inactive track.
    Rectangle {
        x: parent.width * root.shown + 3
        y: 14
        width: parent.width * (1 - root.shown) - 3
        height: 16
        radius: 8
        color: "#33FFFFFF" // white .2
    }
    // Active track.
    Rectangle {
        x: 0
        y: 14
        width: parent.width * root.shown - 3
        height: 16
        radius: 8
        color: Theme.primary
    }
    // Handle.
    Rectangle {
        x: parent.width * root.shown - width / 2
        width: 4
        height: 44
        radius: 2
        color: Theme.primary
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => {
            root.dragging = true;
            root.dragValue = Math.max(0, Math.min(1, mouse.x / width));
            root.moved(root.dragValue);
        }
        onPositionChanged: mouse => {
            if (pressed) {
                root.dragValue = Math.max(0, Math.min(1, mouse.x / width));
                root.moved(root.dragValue);
            }
        }
        onReleased: root.dragging = false
        onCanceled: root.dragging = false
    }
}
