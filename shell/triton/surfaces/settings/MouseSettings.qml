import QtQuick
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    title: "Mouse & touchpad"

    SettingGroup {
        title: "Pointer"

        SettingRow {
            title: "Speed"
            Slider {
                width: Metrics.settingsControl
                label: "Pointer speed"
                // Hyprland's sensitivity runs from -1 to 1.
                value: (SettingsService.get("input", "sensitivity", 0) + 1) / 2
                onMoved: v => SettingsService.set("input", "sensitivity", Math.round((v * 2 - 1) * 100) / 100)
            }
        }
    }

    SettingGroup {
        title: "Touchpad"

        SettingRow {
            title: "Natural scrolling"
            subtitle: "Content moves with your fingers"
            Switch {
                label: "Natural scrolling"
                checked: SettingsService.get("input", "naturalScroll", true)
                onToggled: on => SettingsService.set("input", "naturalScroll", on)
            }
        }
        SettingRow {
            title: "Tap to click"
            Switch {
                label: "Tap to click"
                checked: SettingsService.get("input", "tapToClick", true)
                onToggled: on => SettingsService.set("input", "tapToClick", on)
            }
        }
    }
}
