import Quickshell
import QtQuick
import "power"
import "components"

// Power menu verification: full-screen state over the pre-blurred board
// wallpaper (the compositor owns live blur in production; PIL pre-blurs
// here — same visual result).

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols-Filled.ttf") }

    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("board-wallpaper-blurred.jpg")
            fillMode: Image.Pad
        }
        Rectangle {
            anchors.fill: parent
            color: "#40000A1E" // rgb(0 10 30 / .25)
        }

        PowerMenu {
            anchors.fill: parent
            greeting: "Good evening"
            userName: "Sid"
            uptimeText: "Up 3 days, 4 hours"
            unsavedText: "Text Editor has unsaved changes"
            focusIndex: 4
        }
    }
}
