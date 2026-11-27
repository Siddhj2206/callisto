pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.launcher
import qs.tokens

// The launcher in its states with sample data, dark over light.
// Headless: scripts/test-shell.sh --entry gallery-launcher.qml
ShellRoot {
    id: shell

    function row(section, title, subtitle, quick) {
        return { key: title, section: section, title: title, subtitle: subtitle, icon: "", glyph: Icons.apps,
            actions: [{ id: "", label: "Open" }, { id: "w", label: "New window" }, { id: "p", label: "Private window" }],
            quick: quick ? { id: "w", label: quick } : null };
    }

    readonly property var results: [
        row("Apps", "Console", "Terminal emulator · GNOME", "New window"),
        row("Apps", "Contacts", "Address book"),
        row("Apps", "Connections to a machine with an exceedingly long name", "Remote desktops"),
        row("Windows", "Console", "~/niri-shell"),
        row("Commands", "Open Settings", "System")
    ]

    Fonts {}

    FloatingWindow {
        title: "Callisto launcher"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        Column {
            anchors.fill: parent

            Repeater {
                model: ["dark", "light"]

                ThemeScope {
                    id: band
                    required property string modelData
                    mode: modelData
                    width: parent.width
                    height: parent.height / 2

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }

                    component Framed: Material {
                        default property alias content: panel.data
                        property alias panel: panel
                        kind: "thick"
                        radius: Metrics.radiusPanelS
                        width: panel.implicitWidth
                        height: panel.implicitHeight

                        LauncherPanel {
                            id: panel
                            anchors.fill: parent
                        }
                    }

                    Row {
                        x: 24
                        y: 24
                        spacing: 24

                        Framed {
                            Component.onCompleted: {
                                panel.results = shell.results;
                                panel.query = "con";
                                panel.selection = 1;
                                panel.action = 1;
                            }
                        }
                        Framed {
                            Component.onCompleted: {
                                panel.mode = "calc";
                                panel.query = "1248 / 4";
                                panel.expression = "1248 / 4";
                                panel.calcResult = "312";
                            }
                        }
                    }
                }
            }
        }
    }
}
