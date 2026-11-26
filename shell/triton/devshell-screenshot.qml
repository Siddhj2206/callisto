import Quickshell
import QtQuick
import "screenshot"
import "components"

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols-Filled.ttf") }

    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
            fillMode: Image.Pad
        }

        ScreenshotUI {
            anchors.fill: parent
            selection: Qt.rect(560, 220, 800, 470)
            hintSizeText: "800 × 470"
        }
    }
}
