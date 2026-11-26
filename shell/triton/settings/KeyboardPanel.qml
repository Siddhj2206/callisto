pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Keyboard panel: layout, repeat behavior, input polish. All store-backed —
// the engine compiles hyprland input keywords.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Keyboard"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Layout"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.keyboard
            title: "Keyboard layout"
            supporting: "Applies immediately, persists across sessions"

            Row {
                spacing: 8

                Repeater {
                    // The layouts that cover most of the world's keyboards.
                    // xkb names are the store values — the engine pushes them
                    // straight into hyprland's kb_layout.
                    model: [
                        { key: "us", label: "EN US" },
                        { key: "gb", label: "EN UK" },
                        { key: "de", label: "DE" },
                        { key: "fr", label: "FR" },
                        { key: "es", label: "ES" },
                        { key: "it", label: "IT" },
                        { key: "pt", label: "PT" },
                        { key: "ru", label: "RU" },
                        { key: "jp", label: "JP" },
                        { key: "kr", label: "KR" },
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        property bool active: SettingsService.get("input", "keyboardLayout", "us") === modelData.key
                        width: layoutLabel.implicitWidth + 20
                        height: 34
                        radius: 17
                        color: active ? Theme.primary : Theme.surfaceContainerHighest

                        TritonText {
                            id: layoutLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 12
                            weight: TritonText.Weight.SemiBold
                            color: active ? Theme.onprimary : Theme.onsurfacevariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsService.set("input", "keyboardLayout", modelData.key)
                        }
                    }
                }
            }
        }

        SectionLabel { label: "Typing"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            title: "Key repeat"
            supporting: "Held keys repeat automatically"
            TritonSwitch {
                on: SettingsService.get("input", "repeat", true)
                onToggled: v => SettingsService.set("input", "repeat", v)
            }
        }

        SettingRow {
            title: "Repeat rate"
            supporting: SettingsService.get("input", "repeatRate", 25) + " keys/sec once repeating"
            TritonSlider {
                width: 250
                // 10–50 keys/sec mapped onto 0..1
                value: (SettingsService.get("input", "repeatRate", 25) - 10) / 40
                onMoved: v => SettingsService.set("input", "repeatRate", Math.round(10 + v * 40))
            }
        }

        SettingRow {
            title: "Repeat delay"
            supporting: SettingsService.get("input", "repeatDelay", 400) + " ms before repetition starts"
            TritonSlider {
                width: 250
                // 200–600 ms mapped onto 0..1
                value: (SettingsService.get("input", "repeatDelay", 400) - 200) / 400
                onMoved: v => SettingsService.set("input", "repeatDelay", Math.round(200 + v * 400))
            }
        }
    }
}
