pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.patterns
import qs.services

Page {
    id: root

    property string query: ""

    signal chosen(string page)

    readonly property var results: SettingsCatalog.search(query)

    title: "Results for “" + query.trim() + "”"
    subtitle: results.length === 0 ? "Nothing matches." : "Press Enter to open the first."

    SettingGroup {
        Repeater {
            model: root.results

            SettingRow {
                required property var modelData
                glyph: SettingsCatalog.page(modelData.page).glyph
                title: modelData.title
                subtitle: SettingsCatalog.page(modelData.page).title
                clickable: true
                onClicked: root.chosen(modelData.page)
            }
        }
    }
}
