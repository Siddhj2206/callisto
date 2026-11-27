import QtQuick
import qs.foundations
import qs.patterns
import qs.services
import qs.tokens

// Clipboard history on the focused monitor, undimmed like the launcher.
OverlayWindow {
    id: root

    open: ClipboardState.open
    presence: motion
    onDismissed: ClipboardState.dismiss()
    onOpening: {
        panel.reset();
        panel.focusInput();
    }

    Presence {
        id: motion
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
