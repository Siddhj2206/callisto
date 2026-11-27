import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.tokens

// Album art, or a note in the wave when there is none.
Item {
    id: root

    property string source: ""
    property real size: Metrics.mediaArt

    width: size
    height: size

    WaveShape {
        visible: image.status !== Image.Ready
        anchors.fill: parent
        color: Theming.of(root).tertiaryContainer

        Icon {
            anchors.centerIn: parent
            glyph: Icons.musicNote
            points: root.size / 2
            tone: "ontertiarycontainer"
        }
    }

    ClippingRectangle {
        visible: image.status === Image.Ready
        anchors.fill: parent
        radius: width / 2
        color: "transparent"

        Image {
            id: image
            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(root.size * 2, root.size * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
