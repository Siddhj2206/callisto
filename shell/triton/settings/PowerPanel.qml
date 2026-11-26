pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Power panel: profile selection, suspend, screen blanking.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Power"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Power mode"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.batteryFull
            title: "Power saver"
            supporting: "Extends battery life, reduces performance"
        }
        SettingRow {
            icon: Icons.batteryFull
            title: "Balanced"
            supporting: "Default performance and power use"
        }
        SettingRow {
            icon: Icons.batteryFull
            title: "Performance"
            supporting: "Maximum performance, higher power use"
        }

        SectionLabel { label: "Automatic"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            title: "Dim screen when idle"
            TritonSwitch {
                on: SettingsService.get("power", "dimIdle", true)
                onToggled: v => SettingsService.set("power", "dimIdle", v)
            }
        }
        SettingRow {
            title: "Suspend when idle"
            supporting: "After 20 minutes"
            TritonSwitch {
                on: SettingsService.get("power", "suspendIdle", true)
                onToggled: v => SettingsService.set("power", "suspendIdle", v)
            }
        }
    }
}
