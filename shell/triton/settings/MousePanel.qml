pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Mouse & touchpad panel: pointer speed, natural scroll, tap-to-click.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Mouse & touchpad"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Touchpad"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.mouse
            title: "Natural scrolling"
            supporting: "Content moves with your fingers"
            TritonSwitch {
                on: SettingsService.get("mouse", "naturalScroll", true)
                onToggled: v => SettingsService.set("mouse", "naturalScroll", v)
            }
        }

        SettingRow {
            icon: Icons.mouse
            title: "Tap to click"
            supporting: "A light tap registers as a click"
            TritonSwitch {
                on: SettingsService.get("mouse", "tapToClick", true)
                onToggled: v => SettingsService.set("mouse", "tapToClick", v)
            }
        }

        SettingRow {
            title: "Pointer speed"
            TritonSlider {
                width: 250
                value: 0.5
            }
        }
    }
}
