import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.tokens

// A panel that drops from the top-right corner. A click outside (or Esc)
// dismisses it.
OverlayWindow {
    id: root

    default property alias content: panel.data
    property bool centred: false // under the middle of the bar instead
    property real panelWidth: Metrics.panelWidth
    property real panelHeight: 0
    property real panelRadius: Metrics.radiusPanelM

    // Esc, or Left/Backspace that nothing inside used, asks to step back.
    signal back

    WlrLayershell.namespace: "triton-glass"
    presence: motion
    onOpening: keys.forceActiveFocus()

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
            id: motion
            show: root.open
            fromY: -Metrics.osdRise
            fromScale: Metrics.enterScale
            transformOrigin: root.centred ? Item.Top : Item.TopRight
            x: root.centred ? Math.round((parent.width - width) / 2) : parent.width - width - Metrics.barSide
            y: Metrics.popoverTop
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
