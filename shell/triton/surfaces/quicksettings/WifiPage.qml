pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// Nearby networks. Picking a new secured one asks for its password in place.
ListPage {
    id: root

    property var networks: [] // objects shaped like Quickshell's WifiNetwork
    property var isSecured: network => true
    property string passwordFor: "" // name of the network being asked about
    property string failed: "" // name of the network that just refused

    signal connectRequested(var network, string password)

    title: "Wi-Fi"
    hasSwitch: true
    empty: !checked || networks.length === 0
    emptyText: checked ? "Looking for networks…" : "Wi-Fi is off"
    settingsText: "All network settings"

    function pick(network) {
        failed = "";
        if (network.connected)
            return;
        if (!network.known && isSecured(network)) {
            passwordFor = passwordFor === network.name ? "" : network.name;
            return;
        }
        passwordFor = "";
        connectRequested(network, "");
    }

    function bars(strength) {
        return strength > 0.75 ? Icons.wifi : strength > 0.5 ? Icons.networkWifi3Bar
            : strength > 0.25 ? Icons.networkWifi2Bar : Icons.networkWifi1Bar;
    }

    // ScriptModel keeps rows (and a half-typed password) across rescans.
    Repeater {
        model: ScriptModel { values: root.networks }

        ListRow {
            id: row
            required property var modelData
            required property int index
            readonly property bool asking: root.passwordFor === modelData.name

            width: parent.width
            first: index === 0
            last: index === root.networks.length - 1
            glyph: root.bars(modelData.signalStrength)
            title: modelData.name
            selected: modelData.connected
            subtitle: modelData.connected ? "Connected"
                : modelData.stateChanging ? "Connecting…"
                : root.failed === modelData.name ? "Couldn't connect"
                : modelData.known ? "Saved"
                : root.isSecured(modelData) ? "" : "Open"
            trailingGlyph: modelData.connected ? Icons.checkCircle
                : root.isSecured(modelData) ? Icons.lock : ""
            onClicked: root.pick(modelData)

            Connections {
                // Sample data in the gallery is not a QObject.
                target: typeof row.modelData.connectionFailed === "function" ? row.modelData : null
                ignoreUnknownSignals: true
                function onConnectionFailed() {
                    root.failed = row.modelData.name;
                    if (root.isSecured(row.modelData))
                        root.passwordFor = row.modelData.name;
                }
            }

            Loader {
                width: parent.width
                active: row.asking
                visible: active
                sourceComponent: Row {
                    spacing: Metrics.tileGap

                    function send() {
                        if (field.text.length < 8)
                            return;
                        root.passwordFor = "";
                        root.failed = "";
                        root.connectRequested(row.modelData, field.text);
                    }

                    TextField {
                        id: field
                        width: parent.width - join.width - parent.spacing
                        height: join.height
                        password: true
                        placeholder: "Password"
                        onAccepted: parent.send()
                        Component.onCompleted: focusInput()
                    }
                    Button {
                        id: join
                        height: Metrics.control
                        text: "Join"
                        interactive: field.text.length >= 8
                        opacity: interactive ? 1 : Theme.stateDimmed
                        onClicked: parent.send()
                    }
                }
            }
        }
    }
}
