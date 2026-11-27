pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.overview
import qs.surfaces.switcher
import qs.tokens

// The overview and the window switcher with sample windows (no live previews).
// Headless: scripts/test-shell.sh --entry gallery-windows.qml
ShellRoot {
    id: shell
    Fonts {}

    function sample(address, title, app, workspace, aspect) {
        return { address: address, title: title, app: app, appId: app, icon: "", capture: null,
            workspace: workspace, floating: false, aspect: aspect };
    }
    readonly property var windows: [
        sample("a", "callisto — foot", "Foot", 1, 1.6),
        sample("b", "Mozilla Firefox", "Firefox", 1, 1.2),
        sample("c", "Downloads", "Files", 2, 1.5),
        sample("d", "notes.md", "Text Editor", 2, 0.8),
        sample("e", "Settings", "Settings", 2, 1.4)
    ]

    FloatingWindow {
        title: "Callisto windows"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            OverviewScreen {
                width: 1920
                height: 720
                wallpaper: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                ribbons: [
                    { id: 1, active: true, windows: shell.windows.filter(w => w.workspace === 1) },
                    { id: 2, active: false, windows: shell.windows.filter(w => w.workspace === 2) },
                    { id: 3, active: false, windows: [] }
                ]
                clip: true
                Component.onCompleted: reset()
            }
            Material {
                kind: "thick"
                radius: Metrics.radiusPanelM
                x: switcher.x
                y: switcher.y
                width: switcher.width
                height: switcher.height
            }
            SwitcherPanel {
                id: switcher
                x: (parent.width - width) / 2
                y: 740
                width: implicitWidth
                height: implicitHeight
                windows: shell.windows
                index: 1
            }
        }
    }
}
