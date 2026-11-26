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
