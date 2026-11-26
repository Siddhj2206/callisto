pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../services"

// Overview surface: fullscreen overlay over live windows. Compositor
// thumbnails arrive with the window service — mock ribbons stand in.

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "#66000000"
    visible: OverviewState.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Overview {
        anchors.fill: parent
        workspaces: [
            { num: 1, name: "Work", count: 0, active: true },
        ]
        ribbons: [ { windows: [] } ]

        onWindowPicked: OverviewState.dismiss()
        onCancelled: OverviewState.dismiss()
    }
}
