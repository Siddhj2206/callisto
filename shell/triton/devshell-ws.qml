import Quickshell
import QtQuick
import "windowswitcher"
import "components"

// Window switcher verification: board state — 5 windows, 2nd selected.

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
        Rectangle {
            anchors.fill: parent
            color: "#59000000" // 35% scrim
        }

        WindowSwitcher {
            anchors.centerIn: parent
            headerTitle: "~/triton — Console"
            headerMeta: "Work · workspace 2 · Console · 2nd most recent"
            selected: 1
            windows: [
                { title: "Documents", app: "Files", workspace: "Work", glyph: Icons.folder, thumbKind: "lines" },
                { title: "~/triton", app: "Console", workspace: "Work", glyph: Icons.terminal, thumbKind: "editor" },
                { title: "Triton docs", app: "Browser", workspace: "Work", glyph: Icons.publicIcon, thumbKind: "solid" },
                { title: "Team chat", app: "Chat", workspace: "Chat", glyph: Icons.chat, thumbKind: "chat", attention: true },
                { title: "shell.rs", app: "Editor", workspace: "Work", glyph: Icons.code, thumbKind: "bars", floating: true },
            ]
        }
    }
}
