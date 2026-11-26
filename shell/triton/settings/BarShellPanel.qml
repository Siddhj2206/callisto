pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Bar & Shell panel (SettingsStates): autohide choice cards, indicator
// switches, layout rows. Store-backed; shell re-reads on apply.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Bar & Shell"
        supporting: "Autohide is a first-class choice."
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Layout"; bottomPadding: 8 }

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
