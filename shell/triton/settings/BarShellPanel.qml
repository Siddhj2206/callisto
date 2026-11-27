pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Bar & Shell panel (SettingsStates board, full spec): autohide choice cards
// (Hidden / Reveal on edge / Pinned) with mini bar previews, then reveal
// behavior rows, then indicator switches. Everything store-backed.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Bar & Shell"
    }

    // ---- Autohide cards ----
    Row {
        x: 32
        y: 84
        width: root.width - 64
        spacing: 10

        Repeater {
            model: [
                { id: "hidden", name: "Hidden", desc: "Only on Super" },
                { id: "edge", name: "Reveal on edge", desc: "Pointer at the top edge" },
                { id: "pinned", name: "Pinned", desc: "Always visible" },
            ]

            delegate: Rectangle {
                id: cardDelegate
                required property var modelData
                property bool active: SettingsService.get("shell", "barMode", "edge") === modelData.id
                width: (parent.width - 20) / 3
                height: 158
                radius: 22
                color: active ? Theme.secondaryContainer : Theme.surfaceContainer
                border.width: active ? 0 : 1
                border.color: Theme.outlineVariant

                // Mini wallpaper strip with a bar mock in the card's mode.
                Rectangle {
                    x: 14
                    y: 14
                    width: parent.width - 28
                    height: 76
                    radius: 12
                    color: "#16356F"
                    clip: true

                    // The mock bar: full pill (pinned), edge sliver (edge),
                    // nothing (hidden).
                    Rectangle {
                        visible: cardDelegate.modelData.id === "pinned"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 8
                        width: parent.width - 60
                        height: 16
                        radius: 8
                        color: Theme.glassBg
                    }
                    Rectangle {
                        visible: cardDelegate.modelData.id === "edge"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: parent.width - 60
                        height: 4
                        radius: 2
                        color: Theme.glassBg
                    }
                }

                TritonText {
                    x: 14
                    y: 102
                    text: cardDelegate.modelData.name
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 15
                    color: Theme.onsurface
                }
                TritonText {
                    x: 14
                    y: 122
                    text: cardDelegate.modelData.desc
                    font.pixelSize: 12
                    color: Theme.onsurfacevariant
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsService.set("shell", "barMode", cardDelegate.modelData.id)
                }
            }
        }
    }

    Column {
        x: 32
        y: 262
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Autohide"; bottomPadding: 8 }

        SettingRow {
            title: "Reveal edge"
            supporting: "Top is where the bar lives"
        }
        SettingRow {
            title: "Reveal delay"
            supporting: SettingsService.get("shell", "revealDelay", 120) + " ms at the edge before the bar appears"
            TritonSlider {
                width: 250
                // 0–1000 ms mapped onto 0..1
                value: SettingsService.get("shell", "revealDelay", 120) / 1000
                onMoved: v => SettingsService.set("shell", "revealDelay", Math.round(v * 100) * 10)
            }
        }
        SettingRow {
            title: "Reveal on urgent notification"
            supporting: "The bar peeks for 4 s then hides"
            TritonSwitch {
                on: SettingsService.get("shell", "revealOnUrgent", true)
                onToggled: v => SettingsService.set("shell", "revealOnUrgent", v)
            }
        }

        SectionLabel { label: "Indicators"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            title: "Show window title"
            supporting: "Next to workspaces when revealed"
            TritonSwitch {
                on: SettingsService.get("shell", "showWindowTitle", true)
                onToggled: v => SettingsService.set("shell", "showWindowTitle", v)
            }
        }
        SettingRow {
            title: "Battery as wavy ring"
            TritonSwitch {
                on: SettingsService.get("shell", "batteryWavyRing", false)
                onToggled: v => SettingsService.set("shell", "batteryWavyRing", v)
            }
        }

        SectionLabel { label: "Shell"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            icon: Icons.schedule
            title: "24-hour clock"
            supporting: "Otherwise 12-hour with AM/PM"
            TritonSwitch {
                on: SettingsService.get("shell", "clockFormat", "24h") === "24h"
                onToggled: v => SettingsService.set("shell", "clockFormat", v ? "24h" : "12h")
            }
        }
        SettingRow {
            icon: Icons.animation
            title: "Reduce motion"
            supporting: "120 ms fades replace spatial motion"
            TritonSwitch {
                on: SettingsService.get("shell", "reduceMotion", false)
                onToggled: v => SettingsService.set("shell", "reduceMotion", v)
            }
        }
    }
}
