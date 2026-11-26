pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
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
    // Visibility is a pure binding on the state singleton. The old copy-out
    // property + imperative onOpenChanged only ever opened — IPC-driven close
    // paths (qs ipc call launcher toggle) left the window visible with
    // exclusive keyboard focus while the state thought it was closed.
    visible: LauncherState.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    function dismiss() {
        LauncherState.dismiss();
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

    // Opening resets the search — the launcher is a fresh query every time,
    // not a continuation of whatever you typed yesterday.
    Connections {
        target: LauncherState
        function onOpenChanged() {
            if (LauncherState.open)
                LauncherService.reset();
        }
    }

    LauncherPanel {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        // Centered slightly above middle — modal surfaces sit at optical
        // center, per the boards' placement.
        y: Math.round((root.height - height) * 0.42)
        visible: root.visible

        query: LauncherService.query
        mode: LauncherService.mode
        results: LauncherService.results
        topHitGlyph: Icons.apps
        topHitName: LauncherService.topHit ? (LauncherService.topHit.name || "") : ""
        topHitSubtitle: LauncherService.topHit ? (LauncherService.topHit.genericName || LauncherService.topHit.comment || "") : ""
        topHitActions: LauncherService.topHit ? [{ text: "Launch" }] : []
        calcExpression: LauncherService.mode === 1 ? LauncherService.query.slice(1) : ""
        calcResult: LauncherService.calcResult

        onQueryEdited: text => LauncherService.query = text
        onClosed: root.dismiss()
        onActivated: idx => {
            LauncherService.activateSelection(idx);
            root.dismiss();
        }
    }
}
