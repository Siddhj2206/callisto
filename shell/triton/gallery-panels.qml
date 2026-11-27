pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.quicksettings
import qs.tokens

// Drop-down panels with sample data, dark over light. Headless:
// scripts/test-shell.sh --entry gallery-panels.qml
ShellRoot {
    Fonts {}

    FloatingWindow {
        title: "Callisto panels"
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

                    component Framed: Item {
                        id: framed
                        property alias detail: panel.detail
                        default property alias content: panel.mainPage
                        width: Metrics.panelWidth
                        height: panel.implicitHeight

                        Material {
                            anchors.fill: parent
                            radius: Metrics.radiusPanelM
                        }
                        QsPanel {
                            id: panel
                            anchors.fill: parent
                            clip: true
                        }
                    }

                    Row {
                        x: 24
                        y: 24
                        spacing: 24

                        Framed {
                            MainPage {
                                width: parent.width
                                tiles: [
                                    { key: "wifi", glyph: Icons.wifi, title: "Wi-Fi", subtitle: "Neptuno-5G", on: true, drillable: true },
                                    { key: "bluetooth", glyph: Icons.bluetooth, title: "Bluetooth", subtitle: "2 devices", on: true, drillable: true },
                                    { key: "sound", glyph: Icons.volumeUp, title: "Sound", subtitle: "Speakers", on: false, drillable: true },
                                    { key: "nightLight", glyph: Icons.nightlight, title: "Night light", subtitle: "Until 06:30", on: true, drillable: false }
                                ]
                                brightness: 0.7
                                volume: 0.42
                            }
                        }

                        Framed {
                            detail: Component {
                                WifiPage {
                                    checked: true
                                    passwordFor: "Cafe Orbital"
                                    networks: [
                                        { name: "Neptuno-5G", signalStrength: 0.9, connected: true, known: true, stateChanging: false },
                                        { name: "Neptuno-2G", signalStrength: 0.7, connected: false, known: true, stateChanging: false },
                                        { name: "Cafe Orbital", signalStrength: 0.4, connected: false, known: false, stateChanging: false },
                                        { name: "A network with a very long name that cannot fit", signalStrength: 0.2, connected: false, known: false, stateChanging: false }
                                    ]
                                }
                            }
                        }

                        Framed {
                            detail: Component {
                                BluetoothPage {
                                    checked: true
                                    devices: [
                                        { name: "WH-1000XM5", icon: "audio-headset", connected: true, batteryAvailable: true, battery: 0.8 },
                                        { name: "MX Keys", icon: "input-keyboard", connected: false, batteryAvailable: false }
                                    ]
                                }
                            }
                        }

                        Framed {
                            detail: Component {
                                SoundPage {
                                    current: "a"
                                    outputs: [{ node: "a", name: "Built-in speakers" }, { node: "b", name: "Headphones" }]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
