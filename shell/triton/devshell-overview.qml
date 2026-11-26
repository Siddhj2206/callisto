import Quickshell
import QtQuick
import "overview"
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
            source: Qt.resolvedUrl("board-wallpaper-overview.jpg")
            fillMode: Image.Pad
        }

        Overview {
            anchors.fill: parent
            workspaces: [
                { num: 2, name: "Chat", count: 2, active: false },
                { num: 1, name: "Work", count: 4, active: true },
                { num: 3, name: "Media", count: 2, active: false },
            ]
            ribbons: [
                { windows: [
                    { app: "Chat", glyph: Icons.chat, kind: "lines" },
                    { app: "Mail", glyph: Icons.mail, kind: "lines", dark: false },
                ] },
                { windows: [
                    { app: "Text Editor", glyph: Icons.notes, kind: "editor" },
                    { app: "Files", glyph: Icons.folder, kind: "editor", focused: true },
                    { app: "Console", glyph: Icons.terminal, kind: "editor" },
                    { app: "Web", glyph: Icons.publicIcon, kind: "lines", dark: false },
                ] },
                { windows: [
                    { app: "Music", glyph: Icons.musicNote || Icons.terminal, kind: "lines" },
                    { app: "Video", glyph: Icons.videocam, kind: "lines" },
                ] },
            ]
        }
    }
}
