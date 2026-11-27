import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.osd
import qs.tokens

// Bottom-center window for the OSD, on the focused monitor. It never takes
// focus and lets all pointer input through.
PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: Metrics.osdHeight + Metrics.osdBottom + Metrics.osdRise
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: presence.mapped
    mask: Region {}

    // Pick the monitor only while hidden: moving a mapped window remaps it.
    Connections {
        target: OsdState
        function onOpenChanged() {
            if (!OsdState.open || presence.mapped)
                return;
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
    }

    Presence {
        id: presence
        show: OsdState.open
        fromY: Metrics.osdRise
        fromScale: Metrics.enterScale
        token: Motion.spatialFast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.osdBottom
        width: pill.width
        height: pill.height

        OsdPill {
            id: pill
            kind: OsdState.kind
            value: OsdState.value
        }
    }
}
