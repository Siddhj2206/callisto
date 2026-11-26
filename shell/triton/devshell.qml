pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "components"

// Development harness: renders atoms and primitives against flat surfaces so
// they can be verified in isolation with the headless sway screenshot loop.
// Never shipped — shell.qml is the production entry point.

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

    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: 800
        color: Theme.surface

        Column {
            x: 40; y: 40
            spacing: 24

            // -- Atom test 1: icons + text in a 44px primary-container pill,
            //    vertically centered — the exact composition of the bar's
            //    status group.
            Rectangle {
                width: pillRow.implicitWidth + 36; height: 44
                radius: 22
                color: Theme.primaryContainer

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 16

                    TritonIcon { glyph: Icons.wifi; color: Theme.onprimarycontainer; anchors.verticalCenter: parent.verticalCenter }
                    TritonIcon { glyph: Icons.volumeUp; color: Theme.onprimarycontainer; anchors.verticalCenter: parent.verticalCenter }
                    TritonIcon { glyph: Icons.battery5Bar; color: Theme.onprimarycontainer; anchors.verticalCenter: parent.verticalCenter }
                    TritonText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "82%"
                        font.pixelSize: 15
                        weight: TritonText.Weight.SemiBold
                        color: Theme.onprimarycontainer
                    }
                }
            }

            // -- Atom test 2: filled icon variant.
            Row {
                spacing: 16
                TritonIcon { glyph: Icons.settings; size: 28 }
                TritonIcon { glyph: Icons.settings; size: 28; fill: true }
                TritonIcon { glyph: Icons.notifications; size: 28 }
                TritonIcon { glyph: Icons.notifications; size: 28; fill: true }
            }

            // -- Atom test 3: type ramp.
            TritonText {
                text: "21:41"
                family: TritonText.Family.Display
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 26
            }
            TritonText {
                text: "Sat 21 Nov — Google Sans Flex regular 13"
                font.pixelSize: 13
                color: Theme.onsurfacevariant
            }
            TritonText {
                text: "JetBrains Mono Medium 13 — 0xDEADBEEF"
                family: TritonText.Family.Mono
                weight: TritonText.Weight.Medium
                font.pixelSize: 13
            }
        }
    }
}
