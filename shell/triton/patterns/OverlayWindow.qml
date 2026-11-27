import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations

// A transparent window over the whole focused screen: it holds the keyboard
// while open, reports clicks outside its content, and stays up until the
// content's Presence has faded.
PanelWindow {
    id: root

    default property alias layers: area.data
    property bool open: false
    required property Presence presence

    signal opening // on its screen, about to show
    signal dismissed // a click outside

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
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
        // Not while still fading out, or it would jump between screens.
        if (presence.opacity === 0) {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
        opening();
    }

    Item {
        id: area
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }
}
