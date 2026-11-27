pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.patterns
import qs.services

Page {
    title: "Apps"

    Component.onCompleted: AppsService.refresh()

    SettingGroup {
        title: "Opens with"

        Repeater {
            model: [
                { key: "browser", title: "Web links", glyph: Icons.publicIcon },
                { key: "files", title: "Folders", glyph: Icons.folder },
                { key: "images", title: "Pictures", glyph: Icons.image },
            ]

            SettingRow {
                required property var modelData
                glyph: modelData.glyph
                title: modelData.title
                subtitle: AppsService.defaults[modelData.key] ? AppsService.appName(AppsService.defaults[modelData.key]) : "Nothing set"
            }
        }
    }

    SettingGroup {
        title: "Installed from Flathub"

        Repeater {
            model: AppsService.flatpaks

            SettingRow {
                required property var modelData
                title: modelData[0]
                subtitle: modelData[1] ?? ""
            }
        }
        SettingRow {
            visible: AppsService.listed && AppsService.flatpaks.length === 0
            title: "None yet"
        }
    }
}
