import Quickshell
import QtQuick
import "notifications"
import "components"

// Notification verification harness: toasts column and center panel at the
// board's exact positions over the board wallpaper, mock content.

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
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

        // Toast column: board positions it right:24px top:24px inside a
        // stage at x64 y262 w760 h640 — absolute x = 64+760-24-400 = 400,
        // y = 286. In real use the column is right-anchored below the bar.
        Column {
            x: 400
            y: 286
            width: 400
            spacing: 10

            NotificationCard {
                width: 400
                kind: NotificationCard.Kind.Message
                initials: "MK"
                title: "Mia"
                timeText: "now"
                body: "Thinking ramen at 1, you in?"
                hasReply: true
            }

            NotificationCard {
                width: 400
                kind: NotificationCard.Kind.Progress
                iconGlyph: Icons.folderCopy
                title: "Copying 3 files"
                timeText: "1.2 GB"
                body: "To Backups"
                progress: 0.58
                progressText: "58%"
                actions: [{ text: "Cancel", style: "pt", small: true }]
            }
        }

        // "2 more" pill, right-aligned below the column.
        Rectangle {
            x: 400 + 400 - width
            y: 286 + 220 // below the two toasts approximately; adjusted visually
            height: 36
            width: moreRow.implicitWidth + 32
            radius: 18
            color: Theme.glassBg

            Row {
                id: moreRow
                anchors.centerIn: parent
                spacing: 8

                TritonIcon {
                    glyph: Icons.stacks
                    size: 18
                    color: Theme.onsurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                TritonText {
                    text: "2 more"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 13
                    color: Theme.onsurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Notification center: board position right:20 top:20 bottom:20 of
        // the stage at x864 y262 w718 h640 → abs x = 864+718-20-440 = 1122,
        // y = 282, height = 600.
        NotificationCenter {
            x: 1122
            y: 282
            height: 600
            groups: [
                {
                    app: "Chat", glyph: Icons.chat, fillGlyph: true,
                    discColor: Theme.tertiaryContainer, discContentColor: Theme.ontertiarycontainer,
                    count: 3, countText: "3 new", expanded: true, clearable: true, hiddenCount: 1,
                    items: [
                        { title: "Mia", preview: "Thinking ramen at 1, you in?", time: "now" },
                        { title: "Dev group", preview: "Priya: build is green again", time: "12 min" },
                    ]
                },
                {
                    app: "Calendar", glyph: Icons.event, fillGlyph: true,
                    discColor: Theme.secondaryContainer, discContentColor: Theme.onsecondarycontainer,
                    count: 1, expanded: true,
                    items: [
                        { title: "Design review", preview: "Tomorrow, 10:00 · Room 4", time: "1 h" },
                    ]
                },
                {
                    app: "Software", glyph: Icons.systemUpdate, fillGlyph: false,
                    discColor: Theme.surfaceContainerHighest, discContentColor: Theme.onsurfacevariant,
                    count: 2, expanded: false,
                    items: [
                        { title: "3 updates ready", preview: "Neptuno · restart to apply", time: "2 h" },
                        { title: "hidden", preview: "", time: "" },
                    ]
                },
            ]
        }

        // Card types row: standard / message / critical examples.
        NotificationCard {
            x: 88
            y: 1030
            width: 480
            kind: NotificationCard.Kind.Standard
            iconGlyph: Icons.mail
            discColor: Theme.secondaryContainer
            title: "Standard"
            timeText: "2 min"
            body: "Title, one or two lines of body, app icon. Tap to open the app."
        }

        NotificationCard {
            x: 1130
            y: 1030
            width: 480
            kind: NotificationCard.Kind.Critical
            iconGlyph: Icons.warning
            title: "Critical"
            timeText: "now"
            body: "Error container. Stays until dismissed, ignores Do Not Disturb."
            actions: [{ text: "Power saver", style: "pf" }, { text: "Dismiss", style: "pe" }]
        }
    }
}
