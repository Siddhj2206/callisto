pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Bar & Shell"

    readonly property Scheme scheme: Theming.of(root)
    readonly property string mode: SettingsService.barMode
    readonly property int revealDelay: SettingsService.revealDelay

    SettingGroup {
        SettingRow {
            title: "Bar"
            below: Row {
                width: parent.width
                spacing: Metrics.rowGap

                Repeater {
                    id: choices
                    model: [
                        { value: "edge", title: "Reveal on edge", caption: "Hidden until the pointer reaches the top" },
                        { value: "hidden", title: "Hidden", caption: ShortcutsService.keysOf("bar") ? "Only on its shortcut" : "Until a shortcut is set" },
                        { value: "pinned", title: "Pinned", caption: "Always there, windows sit below" },
                    ]

                    OptionCard {
                        id: card
                        required property var modelData
                        width: (parent.width - parent.spacing * (choices.count - 1)) / choices.count
                        title: modelData.title
                        caption: modelData.caption
                        selected: root.mode === modelData.value
                        onClicked: SettingsService.set("shell", "barMode", modelData.value)

                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.listOuter
                            color: root.scheme.surfaceContainerHighest

                            Rectangle {
                                visible: card.modelData.value !== "hidden"
                                readonly property bool strip: card.modelData.value === "pinned"
                                x: strip ? 0 : Metrics.rowGap
                                y: strip ? 0 : Metrics.rowGap
                                width: strip ? parent.width : parent.width * 0.5
                                height: Metrics.rowPad
                                radius: strip ? 0 : height / 2
                                color: root.scheme.primary
                            }
                        }
                    }
                }
            }
        }
        SettingRow {
            visible: root.mode === "edge"
            title: "Reveal delay"
            subtitle: root.revealDelay + " ms at the edge"
            Slider {
                width: Metrics.settingsControl
                label: "Reveal delay"
                // 0 to 1000 ms.
                value: root.revealDelay / 1000
                onMoved: v => SettingsService.set("shell", "revealDelay", Math.round(v * 100) * 10)
            }
        }
        SettingRow {
            visible: root.mode !== "pinned"
            title: "Show it for urgent notifications"
            Switch {
                label: "Show the bar for urgent notifications"
                checked: SettingsService.revealOnUrgent
                onToggled: on => SettingsService.set("shell", "revealOnUrgent", on)
            }
        }
    }

    SettingGroup {
        title: "On the bar"

        SettingRow {
            title: "Window title"
            Switch {
                label: "Window title"
                checked: SettingsService.showWindowTitle
                onToggled: on => SettingsService.set("shell", "showWindowTitle", on)
            }
        }
        SettingRow {
            title: "Battery as a wavy ring"
            Switch {
                label: "Battery as a wavy ring"
                checked: SettingsService.batteryWavyRing
                onToggled: on => SettingsService.set("shell", "batteryWavyRing", on)
            }
        }
        SettingRow {
            title: "24-hour clock"
            subtitle: "Also on the lock screen"
            Switch {
                label: "24-hour clock"
                checked: SettingsService.clock24h
                onToggled: on => SettingsService.set("shell", "clockFormat", on ? "24h" : "12h")
            }
        }
    }
}
