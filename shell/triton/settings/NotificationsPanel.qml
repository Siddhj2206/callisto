pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Notifications panel: DND, lockscreen visibility, critical behavior —
// the store-backed notification policy knobs.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Notifications"
        supporting: "What reaches you, and when."
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Behavior"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.notificationsOff
            title: "Do not disturb"
            supporting: "Only critical alerts and calls break through"
            TritonSwitch {
                on: SettingsService.get("notifications", "dnd", false)
                onToggled: v => SettingsService.set("notifications", "dnd", v)
            }
        }

        SettingRow {
            icon: Icons.lock
            title: "On the lock screen"
            supporting: "Show notification content while locked"
            TritonSwitch {
                on: SettingsService.get("notifications", "lockscreenNotifications", true)
                onToggled: v => SettingsService.set("notifications", "lockscreenNotifications", v)
            }
        }
    }
}
