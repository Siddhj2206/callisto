import Quickshell
import QtQuick
import "quicksettings"
import "components"

// Quick settings verification: main panel and Wi-Fi drill-in at the board's
// exact positions (x760/x1190 y44) over the board wallpaper with the 25%
// scrim the board uses.

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
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
            color: "#40000000" // board scrim rgb(0 0 0 / .25)
        }

        // Main panel: board x760 y44.
        QuickSettingsPanel {
            x: 760
            y: 44
            tiles: [
                { glyph: Icons.wifi, fillGlyph: true, label: "Wi-Fi", sublabel: "Neptuno-5G", on: true, drillable: true },
                { glyph: Icons.bluetooth, fillGlyph: true, label: "Bluetooth", sublabel: "2 devices", on: true, drillable: true },
                { glyph: Icons.volumeUp, label: "Sound", sublabel: "Speakers", on: false, drillable: true },
                { glyph: Icons.bedtime, fillGlyph: true, label: "Night light", sublabel: "Until 06:30", on: true, drillable: false },
            ]
            brightness: 0.7
            volume: 0.42
        }

        // Wi-Fi drill-in: board x1190 y44.
        QuickSettingsPanel {
            x: 1190
            y: 44
            page: QuickSettingsPanel.Page.Wifi
            wifiEnabled: true
            wifiNetworks: [
                { glyph: Icons.wifi, name: "Neptuno-5G", status: "Connected · WPA3", connected: true },
                { glyph: Icons.networkWifi3Bar, name: "Neptuno-2G", status: "Saved" },
                { glyph: Icons.networkWifi2Bar, name: "Cafe Orbital", status: "WPA2" },
                { glyph: Icons.networkWifi1Bar, name: "Hidden network", status: "Enter name" },
            ]
        }
    }
}
