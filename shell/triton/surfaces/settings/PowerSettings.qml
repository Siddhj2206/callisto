pragma ComponentBehavior: Bound

import Quickshell.Services.UPower
import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services

Page {
    title: "Power"

    SettingGroup {
        title: "Power mode"

        // power-profiles-daemon remembers the choice itself.
        Repeater {
            model: [
                { profile: PowerProfile.PowerSaver, title: "Power saver", subtitle: "Longer battery, less speed" },
                { profile: PowerProfile.Balanced, title: "Balanced", subtitle: "The usual choice" },
                { profile: PowerProfile.Performance, title: "Performance", subtitle: "More speed, more power" },
            ].filter(m => m.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

            SettingRow {
                required property var modelData
                title: modelData.title
                subtitle: modelData.subtitle
                selected: PowerProfiles.profile === modelData.profile
                glyph: selected ? Icons.checkCircle : Icons.bolt
                clickable: true
                onClicked: PowerProfiles.profile = modelData.profile
            }
        }
    }

    SettingGroup {
        title: "When idle"

        SettingRow {
            title: "Turn the screen off"
            subtitle: "After 10 minutes"
            Switch {
                label: "Turn the screen off when idle"
                checked: SettingsService.get("power", "dimIdle", true)
                onToggled: on => SettingsService.set("power", "dimIdle", on)
            }
        }
        SettingRow {
            title: "Suspend"
            subtitle: "After 20 minutes"
            Switch {
                label: "Suspend when idle"
                checked: SettingsService.get("power", "suspendIdle", true)
                onToggled: on => SettingsService.set("power", "suspendIdle", on)
            }
        }
    }
}
