pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.wallpaper
import qs.tokens

// The wallpaper picker with the board images as sample wallpapers.
// Headless: scripts/test-shell.sh --entry gallery-wallpaper.qml
ShellRoot {
    Fonts {}

    function file(name) {
        return Qt.resolvedUrl(name + ".jpg").toString().replace("file://", "");
    }

    FloatingWindow {
        title: "Callisto wallpaper picker"
        implicitWidth: 1280
        implicitHeight: 800
        color: "#101014"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            Crossfade {
                anchors.fill: parent
                source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
            }
            PaletteCard {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Metrics.panelPad
                palette: ({ dark: { primary: "#B0C6FF", secondary: "#BFC6DC", tertiary: "#FFB59B", primary_container: "#00429B", surface_container_high: "#282A2F" } })
            }
            Material {
                kind: "thick"
                radius: Metrics.radiusPanelM
                anchors.fill: dock
            }
            WallpaperDock {
                id: dock
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Metrics.panelPad
                height: implicitHeight
                current: file("board-wallpaper")
                selection: 1
                items: ["board-wallpaper", "board-wallpaper-lock", "board-wallpaper-greeter", "board-wallpaper-overview"]
                    .map(n => ({ path: file(n), name: n, source: "system" }))
            }
        }
    }
}
