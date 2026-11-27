pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services

Page {
    title: "Bluetooth"

    Component.onCompleted: BluetoothService.scan(true)
    Component.onDestruction: BluetoothService.scan(false)

    SettingGroup {
        SettingRow {
            glyph: BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothDisabled
            title: "Bluetooth"
            subtitle: BluetoothService.statusText
            Switch {
                label: "Bluetooth"
                visible: BluetoothService.available
                checked: BluetoothService.enabled
                onToggled: on => {
                    BluetoothService.setEnabled(on);
                    BluetoothService.scan(on);
                }
            }
        }
    }

    SettingGroup {
        title: "Devices"
        visible: BluetoothService.enabled

        Repeater {
            model: BluetoothService.devices

            SettingRow {
                required property var modelData
                glyph: modelData.connected ? Icons.bluetoothConnected : Icons.bluetooth
                title: modelData.name
                selected: modelData.connected
                subtitle: modelData.connected ? "Connected, click to disconnect"
                    : modelData.paired ? "Paired, click to connect" : "Click to pair"
                clickable: true
                onClicked: BluetoothService.toggleDevice(modelData)
            }
        }
        SettingRow {
            visible: BluetoothService.devices.length === 0
            title: "Looking for devices"
            subtitle: "Put the other device in pairing mode and keep it close"
        }
    }
}
