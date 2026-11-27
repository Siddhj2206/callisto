import QtQuick
import qs.foundations
import qs.tokens

// How far along something is.
Item {
    id: root

    property real value: 0 // 0..1
    readonly property Scheme scheme: Theming.of(root)

    implicitHeight: Metrics.progressHeight

    Spring {
        id: level
        to: Math.max(0, Math.min(1, root.value))
        epsilon: 0.001
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.scheme.veilHi
    }
    Rectangle {
        width: Math.max(height, parent.width * level.value)
        height: parent.height
        radius: height / 2
        color: root.scheme.primary
    }
}
