pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import ".."
import "../components"
import "../services"

// Apps panel: default applications by category. Browser/terminal/file
// manager associations are xdg-settings in production.

Item {
    id: root

    // The live default browser, read once on panel load. Changing it is a
    // xdg-settings call — the user-facing contract is that this row is never
    // a lie.
    property string currentBrowser: "…"

    Process {
        command: ["xdg-settings", "get", "default-web-browser"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const d = data.trim().replace(/\.desktop$/, "");
                root.currentBrowser = d === "firefox" ? "Firefox" : d;
            }
        }
    }

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
            supporting: root.currentBrowser
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
