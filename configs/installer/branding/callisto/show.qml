import QtQuick
import calamares.slideshow 1.0

Presentation {
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#111318"
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#E2E2E9"
            font.pixelSize: 22
            text: "Copying Callisto to your disk.\nThis takes a few minutes."
        }
    }
}
