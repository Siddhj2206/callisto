pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.bar
import qs.surfaces.tray
import qs.tokens

// Background apps and privacy chips with sample data, dark over light.
// Run: scripts/test-shell.sh --gallery tray
Scope {
    id: shell

    function app(title, attention) {
        return { id: title, title: title, tooltipTitle: "", icon: "", attention: attention };
    }
    function entry(text, extra) {
        return Object.assign({ text: text, enabled: true, isSeparator: false, hasChildren: false, checkState: Qt.Unchecked }, extra);
    }

    Fonts {}

    FloatingWindow {
        title: "Callisto tray"
        implicitWidth: 1280
        implicitHeight: 800
        color: "#101014"

        Column {
            anchors.fill: parent

            Repeater {
                model: ["dark", "light"]

                ThemeScope {
                    id: band
                    required property string modelData
                    mode: modelData
                    width: parent.width
                    height: parent.height / 2

                    Rectangle {
                        anchors.fill: parent
                        color: Theming.of(this).surface

                        Row {
                            anchors.centerIn: parent
                            spacing: Metrics.panelPad * 2

                            TrayPanel {
                                width: Metrics.trayWidth
                                apps: [shell.app("Backup", false), shell.app("VPN", false), shell.app("Updates", true),
                                    shell.app("A very long application name", false)]
                            }
                            TrayPanel {
                                width: Metrics.trayWidth
                                menuTitle: "Backup"
                                entries: [shell.entry("Back up now"), shell.entry("Pause", { checkState: Qt.Checked }),
                                    shell.entry("", { isSeparator: true }), shell.entry("Destinations", { hasChildren: true }),
                                    shell.entry("Unavailable", { enabled: false })]
                            }
                            Column {
                                spacing: Metrics.panelPad
                                PrivacyChips { micApp: "Meet" }
                                PrivacyChips { micApp: "Recorder with a very long name that goes on"; micMuted: true }
                                PrivacyChips { video: "screen"; micApp: "Meet" }
                                PrivacyChips { video: "camera" }
                                PrivacyChips { recording: "00:42" }
                            }
                        }
                    }
                }
            }
        }
    }
}
