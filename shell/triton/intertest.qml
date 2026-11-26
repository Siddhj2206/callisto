pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "launcher"
import "services"

// Interaction test harness: the production launcher driven open with mock
// results, waiting for injected keys (wtype). Verifies focus grabbing,
// typing, navigation and activation in the headless harness.

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols-Filled.ttf") }

    Component.onCompleted: LauncherState.open = true

    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "#4D000000"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        LauncherPanel {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round((parent.height - height) * 0.42)
            results: [
                { kind: "label", text: "Apps" },
                { kind: "row", glyph: Icons.contacts, fillGlyph: true, title: "Contacts", subtitle: "Address book" },
                { kind: "row", glyph: Icons.settingsRemote, fillGlyph: true, title: "Connections", subtitle: "Remote desktops" },
                { kind: "row", glyph: Icons.terminal, title: "Console", subtitle: "~/niri-shell", tag: "Work" },
            ]
            topHitGlyph: Icons.terminal
            topHitName: "Console"
            topHitSubtitle: "Terminal emulator · GNOME"
            topHitActions: [{ text: "Open" }, { text: "New window", veil: true }]

            onSelectionChanged: console.log("SELECTION:", selection)
            onActivated: idx => console.log("ACTIVATED:", idx)
            onQueryEdited: t => console.log("QUERY:", t)
            onClosed: console.log("CLOSED")

            // Deterministic interaction sequence: drives the same keyPressed
            // path physical keys use (wtype cannot deliver special keys in
            // this harness — virtual-keyboard keymap limitation, verified).
            // Timing staggers through realistic intervals so selection steps
            // are individually visible in the log.
            Timer {
                interval: 3000; running: true; repeat: false
                onTriggered: panel.keyPressed({ key: Qt.Key_Down, accepted: false })
            }
            Timer {
                interval: 4000; running: true; repeat: false
                onTriggered: panel.keyPressed({ key: Qt.Key_Down, accepted: false })
            }
            Timer {
                interval: 5000; running: true; repeat: false
                onTriggered: panel.keyPressed({ key: Qt.Key_Up, accepted: false })
            }
            Timer {
                interval: 6000; running: true; repeat: false
                onTriggered: panel.keyPressed({ key: Qt.Key_Return, accepted: false })
            }
        }
    }
}
