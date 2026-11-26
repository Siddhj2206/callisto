import Quickshell
import QtQuick
import "lock"
import "components"

// Lock screen verification: full state over the pre-blurred wallpaper.

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
            source: Qt.resolvedUrl("board-wallpaper-lock.jpg")
            fillMode: Image.Pad
        }
        Rectangle {
            anchors.fill: parent
            color: "#33000A1E" // rgb(0 10 30 / .2)
        }

        LockScreen {
            anchors.fill: parent
            dateText: "Saturday, 21 November"
            timeText: "21:41"
            userName: "Sid"
            userInitials: "SK"
            lockedText: "Locked 4 minutes ago"
            hasCalendar: true
            calendarText: "Tomorrow, 10:00 · Design review"
            notifications: [
                { app: "Mia", type: "Message", glyph: Icons.chat, discColor: Theme.tertiaryContainer, discContentColor: Theme.ontertiarycontainer },
                { app: "Calendar", type: "Event reminder", glyph: Icons.event, discColor: Theme.secondaryContainer, discContentColor: Theme.onsecondarycontainer },
                { app: "Software", type: "Updates ready", glyph: Icons.systemUpdate, discColor: Theme.surfaceContainerHighest, discContentColor: Theme.onsurfacevariant },
            ]
            mediaTitle: "Lofi Windows"
            mediaArtist: "Tomppabeats"
            mediaPlaying: true
            batteryText: "82%"
        }
    }
}
