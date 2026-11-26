pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Bluetooth panel: radio, paired devices, visibility.

Item {
    id: root

    PanelHeader {
        y: 28
        title: "Bluetooth"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Bluetooth"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.bluetooth
            title: "Bluetooth"
            supporting: "Visible to nearby devices"
            TritonSwitch {
                on: true
            }
        }

        SectionLabel { label: "Devices"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            icon: Icons.bluetooth
            title: "No devices paired"
            supporting: "Turn on a device and keep it nearby"
        }
    }
}
