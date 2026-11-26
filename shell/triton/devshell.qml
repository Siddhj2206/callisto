import Quickshell
import QtQuick
import "bar"
import "components"

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
        implicitHeight: 72
        color: "transparent"

        Island {
            x: 16; y: 8

            WaveButton {}

            Item { width: 8; height: 1 }

            Repeater {
                model: 4
                WorkspacePill {
                    required property int index
                    ws: index + 1
                    active: index === 0
                }
            }
        }

        Island {
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 8

            Clock {}

            StatusGroup {
                wifiGlyph: Icons.wifi
                volumeGlyph: Icons.volumeUp
                batteryGlyph: Icons.battery5Bar
                batteryPercent: 82
            }

            BellButton {}
        }
    }
}
