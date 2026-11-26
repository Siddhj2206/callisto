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

        Repeater {
            model: [
                { key: "power-saver", title: "Power saver", supporting: "Extends battery life, reduces performance" },
                { key: "balanced", title: "Balanced", supporting: "Default performance and power use" },
                { key: "performance", title: "Performance", supporting: "Maximum performance, higher power use" },
            ]

            delegate: SettingRow {
                required property var modelData
                icon: Icons.batteryFull
                title: modelData.title
                supporting: modelData.supporting
                // Radio behavior: the active profile shows a filled primary
                // trailing disc; clicking a row selects it.
                TritonIcon {
                    glyph: SettingsService.get("power", "profile", "balanced") === modelData.key ? Icons.checkCircle : Icons.radioButtonUnchecked
                    fill: true
                    size: 24
                    color: SettingsService.get("power", "profile", "balanced") === modelData.key ? Theme.primary : Theme.onsurfacevariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: SettingsService.set("power", "profile", modelData.key)
                }
            }
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
