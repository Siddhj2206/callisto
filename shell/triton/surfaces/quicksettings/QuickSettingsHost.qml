pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.patterns
import qs.services

// Quick settings, wired to the system.
Popover {
    id: root

    readonly property string page: QuickSettingsState.page

    readonly property bool nightLight: SettingsService.nightLight

    open: QuickSettingsState.open
    panelHeight: panel.implicitHeight
    onDismissed: QuickSettingsState.dismiss()
    // Esc leaves a page first, then the panel.
    onBack: page !== "" ? QuickSettingsState.page = "" : QuickSettingsState.dismiss()

    onOpenChanged: {
        if (open)
            panel.rest();
    }
    // Scan only while the Wi-Fi page is up.
    readonly property bool scanning: open && page === "wifi"
    onScanningChanged: NetworkService.scan(scanning)

    function openSettings(page) {
        QuickSettingsState.dismiss();
        SettingsAppState.show(page);
    }

    QsPanel {
        id: panel
        anchors.fill: parent
        detail: root.page === "wifi" ? wifiPage : root.page === "bluetooth" ? bluetoothPage
            : root.page === "sound" ? soundPage : null

        MainPage {
            width: parent.width

            tiles: {
                const list = [];
                if (NetworkService.wifiDevice)
                    list.push({
                        key: "wifi",
                        glyph: NetworkService.wifiEnabled ? Icons.wifi : Icons.wifiOff,
                        title: "Wi-Fi",
                        subtitle: NetworkService.connected ? NetworkService.connectedName
                            : NetworkService.wifiEnabled ? "Not connected" : "Off",
                        on: NetworkService.wifiEnabled,
                        drillable: true
                    });
                if (BluetoothService.available)
                    list.push({
                        key: "bluetooth",
                        glyph: BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothDisabled,
                        title: "Bluetooth",
                        subtitle: BluetoothService.statusText,
                        on: BluetoothService.enabled,
                        drillable: true
                    });
                if (AudioService.available)
                    list.push({
                        key: "sound",
                        glyph: Icons.volume(AudioService.volume, AudioService.muted),
                        title: "Sound",
                        subtitle: AudioService.muted ? "Muted" : AudioService.name(AudioService.sink),
                        on: !AudioService.muted,
                        drillable: true
                    });
                list.push({
                    key: "nightLight",
                    glyph: Icons.nightlight,
                    title: "Night light",
                    subtitle: root.nightLight ? "On" : "Off",
                    on: root.nightLight,
                    drillable: false
                });
                return list;
            }

            hasBrightness: BrightnessService.available
            brightness: BrightnessService.level
            hasVolume: AudioService.available
            volume: AudioService.volume
            muted: AudioService.muted

            media: MediaService.present ? MediaService.current : null
            onMediaToggled: MediaService.togglePlaying()
            onMediaNextRequested: MediaService.next()
            onMediaPreviousRequested: MediaService.previous()
            onMediaRequested: {
                QuickSettingsState.dismiss();
                MediaService.popoverOpen = true;
            }

            onTileToggled: key => {
                if (key === "wifi")
                    NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
                else if (key === "bluetooth")
                    BluetoothService.setEnabled(!BluetoothService.enabled);
                else if (key === "sound")
                    AudioService.toggleMute();
                else if (key === "nightLight")
                    SettingsService.set("display", "nightLight", !root.nightLight);
            }
            onTileDrilled: key => QuickSettingsState.page = key
            onBrightnessMoved: v => BrightnessService.set(v)
            onVolumeMoved: v => AudioService.setVolume(v)
            onMuteToggled: AudioService.toggleMute()
            onSettingsRequested: root.openSettings()
            onPowerRequested: {
                QuickSettingsState.dismiss();
                PowerState.open = true;
            }
        }
    }

    Component {
        id: wifiPage
        WifiPage {
            checked: NetworkService.wifiEnabled
            networks: NetworkService.networks
            isSecured: network => NetworkService.secured(network)
            onBack: QuickSettingsState.page = ""
            onToggled: on => NetworkService.setWifiEnabled(on)
            onConnectRequested: (network, password) => NetworkService.connectTo(network, password)
            onSettingsRequested: root.openSettings("network")
        }
    }

    Component {
        id: bluetoothPage
        BluetoothPage {
            checked: BluetoothService.enabled
            devices: BluetoothService.devices.filter(d => d.paired || d.connected)
                .sort((a, b) => b.connected - a.connected).map(d => d.deviceObj)
            onBack: QuickSettingsState.page = ""
            onToggled: on => BluetoothService.setEnabled(on)
            onDeviceClicked: device => device.connected ? device.disconnect() : device.connect()
            onSettingsRequested: root.openSettings("bluetooth")
        }
    }

    Component {
        id: soundPage
        SoundPage {
            outputs: AudioService.outputs.map(node => ({ node: node, name: AudioService.name(node) }))
            current: AudioService.sink
            onBack: QuickSettingsState.page = ""
            onOutputClicked: node => AudioService.setOutput(node)
            onSettingsRequested: root.openSettings("sound")
        }
    }
}
