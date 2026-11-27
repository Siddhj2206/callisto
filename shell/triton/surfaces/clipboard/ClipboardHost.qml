import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.tokens

// Clipboard history on the focused monitor. Like the launcher: nothing is
// dimmed, and a click outside closes it.
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
    WlrLayershell.keyboardFocus: ClipboardState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: presence.mapped
    mask: ClipboardState.open ? null : nothing

    Region { id: nothing }

    readonly property bool open: ClipboardState.open
    onOpenChanged: {
        if (!open)
            return;
        if (!presence.mapped) {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
        panel.reset();
        panel.focusInput();
    }

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: ClipboardState.dismiss()
        }

        Presence {
            id: presence
            show: root.open
            fromY: -Metrics.osdRise
            fromScale: Metrics.enterScale
            anchors.centerIn: parent
            width: Math.min(panel.implicitWidth, parent.width - Metrics.barSide * 2)
            height: Math.min(panel.implicitHeight, parent.height - Metrics.popoverTop * 2)

            Material {
                anchors.fill: parent
                kind: "thick"
                radius: Metrics.radiusPanelS
            }
            // Clicks on the panel must not reach the dismiss area.
            MouseArea {
                anchors.fill: parent
            }

            ClipboardPanel {
                id: panel
                anchors.fill: parent
                entries: ClipboardState.entries
                available: ClipboardState.available
                previewText: ClipboardState.selectedText
                onSelected: key => ClipboardState.select(key)
                onUsed: (key, paste) => ClipboardState.use(key, paste)
                onPinRequested: (key, pinned) => ClipboardState.pin(key, pinned)
                onDeleteRequested: key => ClipboardState.remove(key)
                onWipeRequested: ClipboardState.wipe()
                onClosed: ClipboardState.dismiss()
            }
        }
    }
}
