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
            supporting: BluetoothService.statusText
            TritonSwitch {
                on: BluetoothService.enabled
                onToggled: v => BluetoothService.setEnabled(v)
            }
        }

        SectionLabel { label: "Devices"; bottomPadding: 8; topPadding: 20 }

        Repeater {
            model: BluetoothService.devices

            delegate: SettingRow {
                required property var modelData
                icon: Icons.bluetooth
                title: modelData.name
                supporting: modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
            }
        }

        SettingRow {
            visible: BluetoothService.devices.length === 0
            icon: Icons.bluetooth
            title: BluetoothService.enabled ? "No devices paired" : "Bluetooth is off"
            supporting: BluetoothService.enabled ? "Turn on a device and keep it nearby" : "Enable Bluetooth to connect devices"
        }
    }
}
