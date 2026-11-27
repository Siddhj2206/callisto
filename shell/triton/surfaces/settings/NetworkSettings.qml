pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Network"

    // The network a password is being typed for.
    property var asking: null

    Component.onCompleted: NetworkService.scan(true)
    Component.onDestruction: NetworkService.scan(false)

    SettingGroup {
        SettingRow {
            visible: NetworkService.wifiDevice !== null
            glyph: NetworkService.wifiEnabled ? Icons.wifi : Icons.wifiOff
            title: "Wi-Fi"
            subtitle: !NetworkService.wifiHardwareEnabled ? "Turned off by a hardware switch"
                : !NetworkService.wifiEnabled ? "Off"
                : NetworkService.connected ? "Connected to " + NetworkService.connectedName : "Not connected"
            Switch {
                label: "Wi-Fi"
                interactive: NetworkService.wifiHardwareEnabled
                checked: NetworkService.wifiEnabled
                onToggled: on => NetworkService.setWifiEnabled(on)
            }
        }
        SettingRow {
            glyph: Icons.lan
            title: "Wired"
            subtitle: NetworkService.wired ? "Connected" : "No cable"
        }
    }

    SettingGroup {
        title: "Networks"
        visible: NetworkService.wifiDevice !== null && NetworkService.wifiEnabled

        Repeater {
            model: NetworkService.networks

            SettingRow {
                id: row
                required property var modelData
                glyph: NetworkService.secured(modelData) ? Icons.wifiLock : Icons.wifi
                title: modelData.name
                selected: modelData.connected
                subtitle: modelData.connected ? "Connected"
                    : Math.round(modelData.signalStrength * 100) + "% signal" + (modelData.known ? ", saved" : "")
                clickable: !modelData.connected
                onClicked: {
                    if (NetworkService.needsPassword(modelData))
                        root.asking = modelData;
                    else
                        NetworkService.connectTo(modelData);
                }

                below: Loader {
                    width: parent.width
                    active: root.asking === row.modelData
                    visible: active
                    sourceComponent: TextField {
                        placeholder: "Password, then Enter"
                        password: true
                        onAccepted: {
                            NetworkService.connectTo(row.modelData, text);
                            root.asking = null;
                        }
                        Component.onCompleted: focusInput()
                    }
                }
            }
        }
    }
}
