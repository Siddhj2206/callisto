pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.lock

// The lock screen with sample data: idle, and after a wrong password on a
// short, narrow screen.
// Headless: scripts/test-shell.sh --entry gallery-lock.qml
ShellRoot {
    Fonts {}

    FloatingWindow {
        title: "Callisto lock screen"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            LockScreen {
                width: 1280
                height: 1080
                wallpaper: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                date: "Saturday, 21 November"
                time: "09:41"
                name: "Sid"
                caption: "Locked 4 minutes ago"
                waiting: [{ app: "Fractal", count: 2 }, { app: "Files", count: 1 }]
                networkGlyph: Icons.wifi
                batteryGlyph: Icons.battery5Bar
                batteryPercent: 82
                clip: true
            }
            LockScreen {
                x: 1280
                width: 640
                height: 480
                wallpaper: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                date: "Saturday, 21 November"
                time: "09:41"
                name: "Sid"
                error: "Wrong password"
                networkGlyph: Icons.lan
                clip: true
                Component.onCompleted: reject()
            }
        }
    }
}
