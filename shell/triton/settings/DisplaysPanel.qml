pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Displays panel (SettingsStates board): arrangement canvas with draggable
// monitor cards on top, then per-display rows — scale stops-slider, refresh
// chips, VRR switch, night light. In production the rows are per-monitor
// sections; v0.1 drives the internal panel.

Item {
    id: root

    // Monitor model: [{name, icon, resolution, x, y, w, h, active}]
    // fed by Hyprland service in production; mock geometry here.
    property var monitors: [
        { name: "eDP-1", label: "Built-in display", icon: Icons.desktopWindows, resolution: "2880 × 1800", active: true },
        { name: "DP-2", label: "", icon: Icons.desktopWindows, resolution: "2560 × 1440", active: false },
    ]

    PanelHeader {
        y: 28
        title: "Displays"
    }

    // ---- Arrangement canvas ----
    Rectangle {
        x: 32
        y: 78
        width: root.width - 64
        height: 190
        radius: 24
        color: Theme.surfaceContainerLow
        border.width: 1
        border.color: Theme.outlineVariant

        // Monitor cards — positions static in v0.1 mock, drag arrives with
        // the monitor service.
        Rectangle {
            x: 150
            y: 38
            width: 240
            height: 130
            radius: 14
            color: Theme.primaryContainer
            border.width: 2
            border.color: Theme.primary

            Column {
                anchors.centerIn: parent
                spacing: 2

                TritonIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: Icons.desktopWindows
                    fill: true
                    size: 22
                    color: Theme.onprimarycontainer
                }
                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "eDP-1"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 14
                    color: Theme.onprimarycontainer
                }
                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "2880 × 1800"
                    family: TritonText.Family.Mono
                    font.pixelSize: 12
                    color: Theme.onprimarycontainer
                    opacity: 0.8
                }
            }
        }

        Rectangle {
            x: 420
            y: 60
            width: 200
            height: 112
            radius: 14
            color: Theme.surfaceContainerHigh

            Column {
                anchors.centerIn: parent
                spacing: 2

                TritonIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: Icons.desktopWindows
                    size: 22
                    color: Theme.onsurfacevariant
                }
                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DP-2"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 14
                    color: Theme.onsurfacevariant
                }
                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "2560 × 1440"
                    family: TritonText.Family.Mono
                    font.pixelSize: 12
                    color: Theme.onsurfacevariant
                    opacity: 0.8
                }
            }
        }

        TritonText {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: "Drag to arrange. Snaps to edges."
            font.pixelSize: 12
            color: Theme.onsurfacevariant
        }
    }

    Column {
        x: 32
        y: 288
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "eDP-1 · Built-in display"; bottomPadding: 8 }

        SettingRow {
            title: "Scale"
            supporting: "Physical 2880 × 1800 · 1.75× gives 1646 × 1029"
            TritonSlider {
                width: 250
                value: 0.7
            }
        }

        SettingRow {
            title: "Refresh rate"
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        { label: "60 Hz", on: false },
                        { label: "120 Hz", on: true },
                        { label: "VRR", on: false },
                    ]

                    delegate: Rectangle {
                        id: rrChip
                        required property var modelData
                        height: 36
                        width: rrLabel.implicitWidth + 32 + (modelData.on ? 20 : 0)
                        radius: 10
                        color: modelData.on ? Theme.primary : "transparent"
                        border.width: modelData.on ? 0 : 1
                        border.color: Theme.outline

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            TritonIcon {
                                visible: rrChip.modelData.on
                                glyph: Icons.check
                                fill: true
                                size: 16
                                color: Theme.onprimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            TritonText {
                                id: rrLabel
                                text: rrChip.modelData.label
                                weight: TritonText.Weight.Medium
                                font.pixelSize: 13
                                color: rrChip.modelData.on ? Theme.onprimary : Theme.onsurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }

        SettingRow {
            title: "Variable refresh rate"
            supporting: "Drops to 48 Hz on static content"
            TritonSwitch {
                on: true
            }
        }

        SettingRow {
            icon: Icons.bedtime
            title: "Night light"
            supporting: "Warm from 21:00 to 06:30 · 3400 K"
            TritonSwitch {
                on: SettingsService.get("display", "nightLight", false)
                onToggled: v => SettingsService.set("display", "nightLight", v)
            }
        }
    }
}
