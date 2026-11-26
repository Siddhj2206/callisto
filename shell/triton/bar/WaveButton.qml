pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."

// The wave launcher button (BarStates `.wv`): the 9-lobe Triton wave in
// Theme.primary with the "apps" icon centered in Theme.onprimary. 44px square
// — the board renders the 100x100-viewBox path scaled into a 44px svg.
// Icon size 22px per the board markup (`.wv i{font-size:22px}`).

Item {
    id: root

    signal clicked

    width: 44
    height: 44

    // PathSvg renders in item coordinates, so the 100x100 path is drawn at
    // natural size and scaled down to 44/100, transform origin at the center.
    Shape {
        width: 100
        height: 100
        anchors.centerIn: parent
        scale: root.width / 100
        antialiasing: true

        ShapePath {
            fillColor: Theme.primary
            strokeColor: "transparent"

            PathSvg {
                path: Theme.wavePath
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "apps"
        color: Theme.onprimary
        font.family: "Triton Symbols"
        font.pixelSize: 22
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
