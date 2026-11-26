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
            supporting: NetworkService.connected ? "Connected to " + NetworkService.connectedName
                      : NetworkService.wifiEnabled ? "Not connected" : "Off"
            TritonSwitch {
                on: NetworkService.wifiEnabled
                onToggled: v => NetworkService.setWifiEnabled(v)
            }
        }

        SectionLabel { label: "Networks"; bottomPadding: 8; topPadding: 20 }

        Repeater {
            model: NetworkService.networks.slice(0, 6)

            delegate: SettingRow {
                required property var modelData
                icon: Icons.wifi
                title: modelData.name
                supporting: (modelData.connected ? "Connected · " : "") + Math.round(modelData.strength) + "% signal"
            }
        }
    }
}
