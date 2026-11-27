pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.tokens

// The launcher on the focused monitor. The window covers the screen, undimmed,
// so that a click outside the panel closes it.
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: LauncherState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: presence.mapped
    mask: LauncherState.open ? null : nothing

    Region { id: nothing }

    readonly property bool open: LauncherState.open
    onOpenChanged: {
        if (!open)
            return;
        if (!presence.mapped) {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
        LauncherService.reset();
        panel.reset();
        panel.query = LauncherState.seed;
        LauncherService.query = LauncherState.seed;
        panel.focusInput();
    }

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: LauncherState.dismiss()
        }

        Presence {
            id: presence
            show: root.open
            fromY: -Metrics.osdRise
            fromScale: Metrics.enterScale
            transformOrigin: Item.Top
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * Metrics.launcherTop)
            width: Math.min(panel.implicitWidth, parent.width - Metrics.barSide * 2)
            height: panel.implicitHeight

            Material {
                anchors.fill: parent
                kind: "thick"
                radius: Metrics.radiusPanelS
            }
            // Clicks on the panel must not reach the dismiss area.
            MouseArea {
                anchors.fill: parent
            }

            LauncherPanel {
                id: panel
                anchors.fill: parent
                mode: LauncherService.mode
                filter: LauncherService.filter
                results: LauncherService.results
                expression: LauncherService.expression
                calcResult: LauncherService.calcResult
                onQueryEdited: text => LauncherService.query = text
                onFilterPicked: name => LauncherService.filter = name
                onCopyRequested: {
                    LauncherService.copyResult();
                    LauncherState.dismiss();
                }
                onActivated: (row, actionId) => {
                    LauncherState.dismiss();
                    row.run(actionId);
                }
                onClosed: LauncherState.dismiss()
            }
        }
    }
}
