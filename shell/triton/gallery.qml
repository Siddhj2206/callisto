pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.surfaces.bar
import qs.surfaces.osd
import qs.tokens

// Component gallery: every shared component in dark and light, with sample
// data. Run `qs -p shell/triton/gallery.qml`, or headless through
// scripts/test-shell.sh --entry gallery.qml. CALLISTO_DENSITY=board shows the
// design-board sizes. Click "Replay motion" to watch enter and exit.
ShellRoot {
    Fonts {}

    FloatingWindow {
        title: "Callisto gallery"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        Row {
            anchors.fill: parent

            Repeater {
                model: ["dark", "light"]

                ThemeScope {
                    id: column
                    required property string modelData
                    mode: modelData
                    width: parent.width / 2
                    height: parent.height

                    property bool replay: true
                    Timer {
                        id: comeBack
                        interval: 500
                        onTriggered: column.replay = true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: column.themeScheme.surface
                    }

                    component Heading: AppText {
                        role: "labelSmall"
                        tone: "primary"
                    }

                    // Bar content over the board wallpaper, so materials read.
                    component Stage: Item {
                        default property alias content: inner.data
                        width: column.width - 48
                        height: inner.childrenRect.height + 16
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                            fillMode: Image.PreserveAspectCrop
                        }
                        Item {
                            id: inner
                            y: 8
                            width: parent.width
                            height: childrenRect.height
                        }
                    }

                    component SampleBar: Bar {
                        width: parent.width
                        activeWorkspace: 1
                        time: "21:41"
                        date: "Sat 21 Nov"
                        volumeGlyph: Icons.volumeUp
                        batteryGlyph: Icons.battery5Bar
                        batteryPercent: 82
                        unread: true
                    }

                    Column {
                        x: 24
                        y: 24
                        spacing: 14

                        AppText {
                            role: "headline"
                            text: (column.modelData === "dark" ? "Dark" : "Light")
                                + (Metrics.board ? " · board sizes" : " · desktop sizes")
                        }

                        Heading { text: "Bar, floating" }
                        Stage {
                            Presence {
                                show: column.replay
                                fromY: -(Metrics.barHeight + Metrics.barTop)
                                width: parent.width
                                height: Metrics.barHeight

                                SampleBar {
                                    networkGlyph: Icons.wifi
                                }
                            }
                        }

                        Heading { text: "Bar, floating, window title" }
                        Stage {
                            SampleBar {
                                networkGlyph: Icons.wifi
                                appName: "Files"
                                windowTitle: "niri-shell"
                            }
                        }

                        Heading { text: "Bar, pinned, do not disturb, low battery" }
                        Stage {
                            SampleBar {
                                pinned: true
                                networkGlyph: Icons.lan
                                batteryPercent: 14
                                batteryGlyph: Icons.batteryAlert
                                statusState: "urgent"
                                dnd: true
                            }
                        }

                        Heading { text: "On-screen display" }
                        Stage {
                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 10

                                Repeater {
                                    model: [["volume", 0.62], ["muted", 0.62], ["brightness", 0.7], ["micOff", 0]]

                                    Presence {
                                        id: sample
                                        required property var modelData
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        show: column.replay
                                        fromY: Metrics.osdRise
                                        fromScale: Metrics.enterScale
                                        token: Motion.spatialFast
                                        width: pill.width
                                        height: pill.height

                                        OsdPill {
                                            id: pill
                                            kind: sample.modelData[0]
                                            value: sample.modelData[1]
                                        }
                                    }
                                }
                            }
                        }

                        Heading { text: "Icon buttons" }
                        Row {
                            spacing: 8
                            Repeater {
                                model: ["standard", "veil", "tonal", "filled"]
                                IconButton {
                                    required property string modelData
                                    glyph: Icons.settings
                                    variant: modelData
                                    label: modelData
                                }
                            }
                            IconButton {
                                glyph: Icons.bedtime
                                selected: true
                                label: "selected"
                            }
                        }

                        Heading { text: "Type" }
                        Column {
                            spacing: 2
                            Repeater {
                                model: Object.keys(Typography.roles)
                                AppText {
                                    required property string modelData
                                    role: modelData
                                    text: modelData + " · Sphinx of black quartz 0123"
                                }
                            }
                        }

                        Pressable {
                            width: replayText.implicitWidth + 32
                            height: Metrics.barSlot + 4
                            fill: column.themeScheme.primary
                            ink: column.themeScheme.onprimary
                            onClicked: {
                                column.replay = false;
                                comeBack.restart();
                            }

                            AppText {
                                id: replayText
                                anchors.centerIn: parent
                                role: "label"
                                tone: "onprimary"
                                text: "Replay motion"
                            }
                        }
                    }
                }
            }
        }
    }
}
