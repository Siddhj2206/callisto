pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Users panel: the live session user. On a live ISO there is exactly one
// user; the installer/first-boot flow owns account creation.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Users"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SettingRow {
            icon: Icons.person
            fillIcon: true
            title: "Live user"
            supporting: "Automatic login · changes reset on reboot"
        }
    }
}
