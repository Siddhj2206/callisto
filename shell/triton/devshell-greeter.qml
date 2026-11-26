import Quickshell
import QtQuick
import "greeter"
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
            source: Qt.resolvedUrl("board-wallpaper-greeter.jpg")
            fillMode: Image.Pad
        }

        Greeter {
            anchors.fill: parent
            timeText: "21:41"
            dateText: "Sat 21 Nov"
            selectedName: "Sid"
            networkName: "Home 5G"
            users: [
                { initials: "MK", name: "Mia", color: "#6B6F78", contentColor: Theme.onsurface },
                { initials: "SK", name: "Sid", color: Theme.tertiaryContainer, contentColor: Theme.ontertiarycontainer },
            ]
            selectedUser: 1
        }
    }
}
