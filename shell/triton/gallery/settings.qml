import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.settings

// Settings with no services behind it.
// Run: scripts/shell.py settings
Scope {
    Fonts {}

    FloatingWindow {
        title: "Callisto settings"
        implicitWidth: 1280
        implicitHeight: 800

        SettingsView {
            anchors.fill: parent
            page: "appearance"
        }
    }
}
