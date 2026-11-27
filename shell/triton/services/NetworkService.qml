pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick

// Network state for the bar and quick settings, over NetworkManager.
Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var devices: Networking.devices.values

    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)

    // The connected Wi-Fi network, if any.
    readonly property var activeNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool connected: activeNetwork !== null
    readonly property bool online: wired || connected
    readonly property string connectedName: activeNetwork?.name ?? ""

    // Visible networks, one per name: the connected one first, then by signal.
    readonly property var networks: {
        const byName = {};
        for (const n of wifiDevice?.networks.values ?? []) {
            if (n.name && (!byName[n.name] || n.connected))
                byName[n.name] = n;
        }
        return Object.values(byName).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
    }

    function secured(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function needsPassword(network) {
        return !network.known && secured(network);
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    function connectTo(network, password) {
        if (password)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function scan(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }
}
