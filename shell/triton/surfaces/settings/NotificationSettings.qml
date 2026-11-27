import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services

Page {
    title: "Notifications"

    SettingGroup {
        SettingRow {
            glyph: Icons.notificationsOff
            title: "Do not disturb"
            subtitle: "Only urgent notifications pop up"
            Switch {
                label: "Do not disturb"
                checked: SettingsService.get("notifications", "dnd", false)
                onToggled: on => SettingsService.set("notifications", "dnd", on)
            }
        }
        SettingRow {
            glyph: Icons.lock
            title: "Content on the lock screen"
            subtitle: "Off hides what notifications say while locked"
            Switch {
                label: "Notification content on the lock screen"
                checked: SettingsService.get("notifications", "lockscreenNotifications", true)
                onToggled: on => SettingsService.set("notifications", "lockscreenNotifications", on)
            }
        }
    }
}
