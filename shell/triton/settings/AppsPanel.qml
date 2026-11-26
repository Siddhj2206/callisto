pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Apps panel: default applications by category. Browser/terminal/file
// manager associations are xdg-settings in production.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Apps"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Defaults"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.webAsset
            title: "Web browser"
            supporting: "Firefox"
        }
        SettingRow {
            icon: Icons.apps
            title: "Files"
            supporting: "Nautilus"
        }
        SettingRow {
            icon: Icons.apps
            title: "Terminal"
            supporting: "foot"
        }
    }
}
