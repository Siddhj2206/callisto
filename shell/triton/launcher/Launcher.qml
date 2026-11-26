pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../services"

// The launcher surface: a fullscreen overlay-layer window holding the 30%
// scrim and the centered panel. Visibility is controlled by the bar's wave
// button and by the panel's own close paths (Esc, selection activation).
//
// The window exists at all times but is invisible when closed — opening is
// then a visibility flip, which keeps the panel's spring animation cheap and
// avoids window-creation latency.

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    property bool open: LauncherState.open

    onOpenChanged: {
        if (open)
            visible = true;
    }

    function dismiss() {
        LauncherState.dismiss();
        root.visible = false;
    }

    // 30% black scrim (Launcher board). Clicking it dismisses.
    Rectangle {
        anchors.fill: parent
        color: "#4D000000"
        visible: root.visible

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }
    }

    LauncherPanel {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        // Centered slightly above middle — modal surfaces sit at optical
        // center, per the boards' placement.
        y: Math.round((root.height - height) * 0.42)
        visible: root.visible

        onClosed: root.dismiss()
        onActivated: root.dismiss()
    }
}
