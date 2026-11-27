pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.patterns
import qs.services
import qs.tokens

// The launcher on the focused monitor, undimmed.
OverlayWindow {
    id: root

    open: LauncherState.open
    presence: motion
    onDismissed: LauncherState.dismiss()
    onOpening: {
        LauncherService.reset();
        panel.reset();
        panel.query = LauncherState.seed;
        LauncherService.query = LauncherState.seed;
        panel.focusInput();
    }

    Presence {
        id: motion
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
