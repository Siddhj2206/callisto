pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Windows panel (SettingsStates board): focus behavior, centering segment.
// Every row is a store-backed switch or segment — edits write through
// SettingsService and the engine recompiles hyprland keywords.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Windows"
        supporting: "Tiling behavior and focus. Applies immediately."
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Focus"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.mouse
            title: "Focus follows mouse"
            supporting: "Moving the pointer over a window focuses it"
            TritonSwitch {
                on: SettingsService.get("windows", "focusFollowsMouse", true)
                onToggled: v => SettingsService.set("windows", "focusFollowsMouse", v)
            }
        }

    }
}
