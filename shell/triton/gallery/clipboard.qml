pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.clipboard
import qs.tokens

// The clipboard with sample entries, dark and light.
// Run: scripts/test-shell.sh --gallery clipboard
Scope {
    id: shell

    function entry(key, kind, title, detail, pinned) {
        return { key: key, kind: kind, title: title, detail: detail, pinned: pinned === true,
            path: kind === "image" ? Qt.resolvedUrl("assets/wallpaper.jpg").toString().replace("file://", "") : "" };
    }

    readonly property var entries: [
        entry("p:1", "link", "https://wiki.hypr.land/Configuring/Basics/Binds/", "Link", true),
        entry("h:2", "image", "Image 1646 × 1029", "PNG · 1646 × 1029 · 412 KB"),
        entry("h:3", "text", "systemctl --user restart callisto-clipboard.service and then a good deal more text", "Text"),
        entry("h:4", "color", "#B0C6FF", "Colour"),
        entry("h:5", "text", "<b>not markup</b>", "Text")
    ]

    Fonts {}

    FloatingWindow {
        title: "Callisto clipboard"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        Grid {
            anchors.fill: parent
            columns: 2

            Repeater {
                model: [
                    { mode: "dark", pick: 1 }, { mode: "light", pick: 3 },
                    { mode: "dark", pick: -1 }, { mode: "light", pick: -2 }
                ]

                ThemeScope {
                    id: cell
                    required property var modelData
                    mode: modelData.mode
                    width: parent.width / 2
                    height: parent.height / 2

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/wallpaper-1646.jpg")
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }
                    Material {
                        anchors.centerIn: parent
                        kind: "thick"
                        radius: Metrics.radiusPanelS
                        width: panel.implicitWidth
                        height: panel.implicitHeight

                        ClipboardPanel {
                            id: panel
                            anchors.fill: parent
                            entries: cell.modelData.pick === -1 ? [] : shell.entries
                            Component.onCompleted: {
                                if (cell.modelData.pick >= 0)
                                    selection = cell.modelData.pick;
                                if (cell.modelData.pick === -2)
                                    confirming = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
