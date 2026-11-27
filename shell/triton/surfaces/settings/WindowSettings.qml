import QtQuick
import qs.patterns
import qs.primitives
import qs.services

Page {
    title: "Windows"

    SettingGroup {
        title: "Focus"

        SettingRow {
            title: "Focus follows the pointer"
            subtitle: "Moving over a window selects it"
            Switch {
                label: "Focus follows the pointer"
                checked: SettingsService.get("windows", "focusFollowsMouse", true)
                onToggled: on => SettingsService.set("windows", "focusFollowsMouse", on)
            }
        }
    }
}
