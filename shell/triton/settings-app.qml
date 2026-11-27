//@ pragma AppId org.callisto.Settings

import Quickshell
import Quickshell.Io
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.settings
import qs.tokens

// The Settings app: its own program, sharing the shell's components and
// services. Opened by bin/callisto-settings; closing the window ends it.
ShellRoot {
    id: root

    Fonts {}
    ThemeSync {}

    FloatingWindow {
        title: "Settings"
        color: "transparent"
        implicitWidth: Metrics.settingsWidth
        implicitHeight: Metrics.settingsHeight
        minimumSize: Qt.size(Metrics.settingsMinWidth, Metrics.settingsMinHeight)
        onVisibleChanged: {
            if (!visible)
                Qt.quit();
        }

        SettingsView {
            id: view
            anchors.fill: parent
            Component.onCompleted: show(Quickshell.env("CALLISTO_SETTINGS_PAGE") || "appearance")
        }
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            view.show(page);
        }
    }
}
