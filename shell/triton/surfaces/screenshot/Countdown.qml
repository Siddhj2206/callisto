import QtQuick
import qs.foundations
import qs.patterns
import qs.tokens

// Seconds until a delayed capture.
Column {
    id: root

    property int seconds: 0

    WaveShape {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Metrics.countdownBadge
        height: width
        color: Theming.of(root).errorContainer

        AppText {
            anchors.centerIn: parent
            role: "display"
            tabular: true
            tone: "onerrorcontainer"
            text: root.seconds
        }
    }
    KeyHint {
        anchors.horizontalCenter: parent.horizontalCenter
        keys: ["Print"]
        text: "cancels"
    }
}
