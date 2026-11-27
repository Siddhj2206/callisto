import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// "[key] [key] what they do", for the foot of keyboard-driven surfaces.
Row {
    id: root

    property var keys: []
    property string text: ""

    spacing: Metrics.cardActions

    Repeater {
        model: root.keys
        Keycap {
            required property string modelData
            text: modelData
        }
    }
    AppText {
        anchors.verticalCenter: parent.verticalCenter
        role: "bodySmall"
        tone: "onsurfacevariant"
        text: root.text
    }
}
