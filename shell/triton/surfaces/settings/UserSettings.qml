import Quickshell
import QtQuick
import qs.patterns
import qs.services
import qs.tokens

Page {
    title: "Users"

    SettingGroup {
        SettingRow {
            title: PowerService.displayName
            subtitle: (Quickshell.env("USER") ?? "")
                + (PowerService.live ? ", the live session. Changes are gone after a restart." : "")

            UserAvatar {
                size: Metrics.control
                name: PowerService.displayName
            }
        }
    }
}
