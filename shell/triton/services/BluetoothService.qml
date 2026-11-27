pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Bluetooth state for quick settings and the settings panel. First-class in
// quickshell 0.2.0+ — no dbus scraping. Degrades to "no adapter" on machines
// without bluetooth hardware.

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available ? adapter.enabled : false

    readonly property var devices: {
        if (!root.available || !root.adapter.devices)
            return [];
        const rows = [];
        for (const d of root.adapter.devices.values) {
            rows.push({
                name: d.name || d.address || "",
                connected: d.connected,
                paired: d.paired,
                deviceObj: d,
            });
        }
        return rows;
    }

    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property string statusText: !available ? "No adapter"
        : !enabled ? "Off"
        : connectedDevices.length > 0 ? connectedDevices[0].name + (connectedDevices.length > 1 ? " +" + (connectedDevices.length - 1) : "")
        : "On"

    function setEnabled(on) {
        if (root.available)
            root.adapter.enabled = on;
    }

    // Looking for new devices costs power, so only while someone is watching.
    function scan(on) {
        if (root.available && root.adapter.enabled)
            root.adapter.discovering = on;
    }

    function toggleDevice(row) {
        const d = row?.deviceObj;
        if (!d)
            return;
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else
            d.pair();
    }

    function connectDevice(row) {
        if (row && row.deviceObj)
            row.deviceObj.connected = true;
    }
}
