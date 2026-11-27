import QtQuick
import qs
import qs.foundations
import qs.tokens

// The launcher button: the wave itself is the button.
Pressable {
    id: root

    label: "Open launcher"
    implicitWidth: Metrics.barSlot
    implicitHeight: Metrics.barSlot

    WaveShape {
        anchors.fill: parent
        color: Theming.of(root).primary

        Icon {
            anchors.centerIn: parent
            glyph: Icons.apps
            tone: "onprimary"
        }
    }
}
