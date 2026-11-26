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
            supporting: "English (US)"
        }

        SectionLabel { label: "Typing"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            title: "Key repeat"
            supporting: "Held keys repeat automatically"
            TritonSwitch {
                on: SettingsService.get("keyboard", "repeat", true)
                onToggled: v => SettingsService.set("keyboard", "repeat", v)
            }
        }

        SettingRow {
            title: "Repeat rate"
            supporting: "Keys per second once repeating"
            TritonSlider {
                width: 250
                value: 0.5
            }
        }

        SettingRow {
            title: "Repeat delay"
            supporting: "Pause before repetition starts"
            TritonSlider {
                width: 250
                value: 0.4
            }
        }
    }
}
