pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../services"

// Clipboard surface: fullscreen overlay with the 35% scrim and the centered
// panel. Closes on paste or click-off — the board's behavior rules.

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: ClipboardState.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
        anchors.fill: parent
        color: "#59000000" // 35% scrim

        MouseArea {
            anchors.fill: parent
            onClicked: ClipboardState.dismiss()
        }
    }

    ClipboardPanel {
        anchors.centerIn: parent
        visible: root.visible

        // Mock history stands in until the clipboard service (data-control)
        // is written — structure and interactions are verified.
        items: [
            { kind: "section", text: "Pinned" },
            { kind: "row", glyph: Icons.terminal, mono: true, title: "ssh sid@neptuno.local -p 2222", meta: "Terminal · pinned", pinned: true },
            { kind: "section", text: "Today" },
            { kind: "row", glyph: Icons.notes, title: "Meeting notes", meta: "Text · Notes", selected: true },
        ]

        onPasted: ClipboardState.dismiss()
    }
}
