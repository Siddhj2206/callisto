pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.greeter

// The login screen with sample data.
// Headless: scripts/test-shell.sh --entry gallery-greeter.qml
ShellRoot {
    Fonts {}

    FloatingWindow {
        title: "Callisto login screen"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            GreeterScreen {
                anchors.fill: parent
                wallpaper: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                date: "Saturday, 21 November"
                time: "21:41"
                users: [{ login: "mia", name: "Mia" }, { login: "sid", name: "Sid" }, { login: "noor", name: "Noor" }]
                selected: 1
                hint: "Live session password: live"
                networkGlyph: Icons.wifi
                batteryGlyph: Icons.battery5Bar
                batteryPercent: 82
            }
        }
    }
}
