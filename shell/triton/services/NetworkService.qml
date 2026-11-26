pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick

// Network state for the bar and quick settings. Thin projection of
// Quickshell.Networking into the shapes the UI consumes: wifi on/off,
// connected network name, scan results as plain row objects.
//
// The 0.3.0 Networking module talks to NetworkManager directly — no nmcli
// scraping, no manual dbus. Where there is no wifi hardware (QEMU, desktops
// on ethernet) the service degrades to wired/empty states.

Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var devices: Networking.devices

    // First wifi device, if any.
    readonly property var wifiDevice: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi)
                return d;
        }
        return null;
    }

    // The currently connected network across all devices.
    readonly property var activeNetwork: {
        for (const d of Networking.devices.values) {
            if (!d.networks)
                continue;
            for (const n of d.networks.values) {
                if (n.connected)
                    return n;
            }
        }
        return null;
    }

    readonly property bool connected: activeNetwork !== null
    readonly property string connectedName: activeNetwork ? (activeNetwork.name || "") : ""
    readonly property real signalStrength: activeNetwork && activeNetwork.signalStrength !== undefined ? activeNetwork.signalStrength : 0

    // Scan results for the drill-in list, plain row objects sorted by
    // signal strength, strongest first, deduplicated by SSID.
    readonly property var networks: {
        const dev = root.wifiDevice;
        if (!dev || !dev.networks)
            return [];
        const seen = {};
        const rows = [];
        for (const n of dev.networks.values) {
            if (!n.name || seen[n.name])
                continue;
            seen[n.name] = true;
            rows.push({
                name: n.name,
                strength: n.signalStrength !== undefined ? n.signalStrength : 0,
                connected: n.connected,
                secure: true, // detailed security flags are per-AP; refine when needed
                networkObj: n,
            });
        }
        rows.sort((a, b) => b.strength - a.strength);
        return rows;
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    function connectTo(row) {
        if (row && row.networkObj)
            row.networkObj.requestConnectWithSettings();
    }

    function rescan() {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = true;
    }
}
