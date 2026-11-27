import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.tokens

// A panel that drops from the top-right corner on the focused monitor. It
// covers the screen invisibly so that a click outside (or Esc) dismisses it,
// and holds the keyboard while open.
PanelWindow {
    id: root

    default property alias content: panel.data
    property bool open: false
    property real panelWidth: Metrics.panelWidth
    property real panelHeight: 0
    property real panelRadius: Metrics.radiusPanelM

    // Esc, or Left/Backspace that nothing inside used, asks to step back.
    signal back
    signal dismissed

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    WlrLayershell.namespace: "triton-glass"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: presence.mapped
    // While fading out, let clicks through.
    mask: open ? null : nothing

    Region { id: nothing }

    onOpenChanged: {
        if (!open)
            return;
        if (!presence.mapped) {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
        keys.forceActiveFocus();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.back()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Backspace)
                root.back();
        }

        Presence {
            id: presence
            show: root.open
            fromY: -Metrics.osdRise
            fromScale: Metrics.enterScale
            transformOrigin: Item.TopRight
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Metrics.popoverTop
            anchors.rightMargin: Metrics.barSide
            width: root.panelWidth
            height: Math.min(root.panelHeight, root.height - Metrics.popoverTop - Metrics.barSide)

            Material {
                anchors.fill: parent
                radius: root.panelRadius
            }
            // Clicks on the panel must not reach the dismiss area.
            MouseArea {
                anchors.fill: parent
            }
            Item {
                id: panel
                anchors.fill: parent
                clip: true
            }
        }
    }
}
