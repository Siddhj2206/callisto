pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Network panel: wifi radio, connected network, known networks.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Network"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Wi-Fi"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.wifi
            fillIcon: true
            title: "Wi-Fi"
            supporting: "Connected to Your Network"
            TritonSwitch {
                on: true
            }
        }

        SectionLabel { label: "Known networks"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            icon: Icons.wifi
            title: "Your Network"
            supporting: "Connected · excellent signal"
        }
    }
}
