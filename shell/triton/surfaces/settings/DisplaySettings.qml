pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Displays"

    readonly property var monitors: Hyprland.monitors.values
    readonly property real scale: SettingsService.get("display", "scale", monitors[0]?.scale ?? 1)

    // Hyprland does not announce a scale change, so ask again after one.
    onScaleChanged: refresh.restart()
    Component.onCompleted: Hyprland.refreshMonitors()
    Timer {
        id: refresh
        interval: Motion.monitorRefresh
        onTriggered: Hyprland.refreshMonitors()
    }

    SettingGroup {
        title: "Connected"

        Repeater {
            model: root.monitors

            SettingRow {
                required property var modelData
                readonly property var info: modelData.lastIpcObject
                glyph: Icons.monitor
                title: modelData.name
                subtitle: modelData.width + " × " + modelData.height
                    + (info?.refreshRate ? " at " + Math.round(info.refreshRate) + " Hz" : "")
                    + ", scale " + Math.round(modelData.scale * 100) + "%"
            }
        }
    }

    SettingGroup {
        title: "Picture"

        SettingRow {
            title: "Scale"
            subtitle: "How large everything is drawn, on every display"
            below: ChoiceChips {
                width: parent.width
                options: [1, 1.25, 1.5, 1.75, 2].map(v => ({ value: v, label: v * 100 + "%" }))
                current: root.scale
                onChosen: value => SettingsService.set("display", "scale", value)
            }
        }
        SettingRow {
            title: "Variable refresh rate"
            subtitle: "On displays that support it"
            Switch {
                label: "Variable refresh rate"
                checked: SettingsService.get("display", "vrr", true)
                onToggled: on => SettingsService.set("display", "vrr", on)
            }
        }
        SettingRow {
            glyph: Icons.nightlight
            title: "Night light"
            subtitle: "Warmer colors, easier on the eyes at night"
            Switch {
                label: "Night light"
                checked: SettingsService.nightLight
                onToggled: on => SettingsService.set("display", "nightLight", on)
            }
        }
    }
}
