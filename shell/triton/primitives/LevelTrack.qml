import QtQuick
import qs.foundations
import qs.tokens

// A read-only level: filled part, rest, and a handle at the boundary.
// The fill springs to new values.
Item {
    id: root

    property real value: 0 // 0..1
    property bool off: false

    readonly property Scheme scheme: Theming.of(root)

    implicitWidth: Metrics.osdTrackWidth
    implicitHeight: Metrics.osdTrackHeight

    Spring {
        id: level
        to: root.off ? 0 : Math.max(0, Math.min(1, root.value))
        token: Motion.spatialFast
        epsilon: 0.001
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.scheme.veilHi
    }
    Rectangle {
        width: root.width * Math.max(0, Math.min(1, level.value))
        height: root.height
        radius: height / 2
        color: root.scheme.primary
    }
    Rectangle {
        visible: !root.off
        x: Math.max(0, Math.min(root.width - width, root.width * level.value - width / 2))
        y: -Metrics.osdHandleOver
        width: Metrics.osdHandleWidth
        height: root.height + Metrics.osdHandleOver * 2
        radius: width / 2
        color: root.scheme.primary
    }
}
