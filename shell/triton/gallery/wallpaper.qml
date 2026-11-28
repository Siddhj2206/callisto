pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.wallpaper
import qs.tokens

// The wallpaper picker with the board images as sample wallpapers.
// Run: scripts/shell.py wallpaper
Scope {
    Fonts {}

    function file(name) {
        return Qt.resolvedUrl("assets/" + name + ".jpg").toString().replace("file://", "");
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
                source: Qt.resolvedUrl("assets/wallpaper-1646.jpg")
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
                current: file("wallpaper")
                selection: 1
                items: ["wallpaper", "wallpaper-lock", "wallpaper-greeter", "wallpaper-overview"]
                    .map(n => ({ path: file(n), name: n, source: "system" }))
            }
        }
    }
}
