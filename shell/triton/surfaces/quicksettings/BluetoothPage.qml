pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.primitives

// Paired devices; picking one connects or disconnects it.
ListPage {
    id: root

    property var devices: [] // objects shaped like Quickshell's BluetoothDevice

    signal deviceClicked(var device)

    title: "Bluetooth"
    hasSwitch: true
    empty: !checked || devices.length === 0
    emptyText: checked ? "No paired devices" : "Bluetooth is off"
    settingsText: "All Bluetooth settings"

    function glyphFor(icon) {
        return /audio|head/.test(icon) ? Icons.headphones : /keyboard/.test(icon) ? Icons.keyboard : Icons.bluetooth;
    }

    Repeater {
        model: ScriptModel { values: root.devices }

        ListRow {
            required property var modelData
            required property int index

            width: parent.width
            first: index === 0
            last: index === root.devices.length - 1
            glyph: root.glyphFor(modelData.icon)
            title: modelData.name
            selected: modelData.connected
            subtitle: !modelData.connected ? "Not connected"
                : modelData.batteryAvailable ? "Connected · " + Math.round(modelData.battery * 100) + "%" : "Connected"
            trailingGlyph: modelData.connected ? Icons.checkCircle : ""
            onClicked: root.deviceClicked(modelData)
        }
    }
}
