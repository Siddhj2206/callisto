import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.tokens

// One per screen: all of them dim, the focused one shows the menu and takes the
// keyboard. Always dark.
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
    WlrLayershell.keyboardFocus: PowerState.open && primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: presence.mapped
    mask: PowerState.open ? null : nothing

    Region { id: nothing }

    // Latched on opening, so that the menu does not jump between screens.
    property bool primary: false
    readonly property bool open: PowerState.open

    onOpenChanged: {
        if (!open) {
            menu.stop();
            return;
        }
        const focused = Hyprland.focusedMonitor?.name;
        primary = Quickshell.screens.some(s => s.name === focused)
            ? focused === screen.name : Quickshell.screens[0] === screen;
        PowerService.refresh();
        menu.reset(PowerState.highlight);
        menu.forceActiveFocus();
    }

    Spring {
        id: grow
        to: root.open ? 1 : Metrics.enterScale
        epsilon: 0.001
    }

    ThemeScope {
        id: scope
        mode: "dark"
        anchors.fill: parent

        Presence {
            id: presence
            show: root.open
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: scope.themeScheme.backdrop
            }
            // The other screens only close the menu.
            MouseArea {
                anchors.fill: parent
                onClicked: PowerState.dismiss()
            }

            PowerMenu {
                id: menu
                visible: root.primary
                focus: true
                anchors.fill: parent
                scale: grow.value

                greeting: root.open ? PowerService.greeting() : greeting
                uptime: PowerService.uptime()
                note: PowerService.blockerNote
                footer: PowerService.hostName && PowerService.hostName !== "callisto"
                    ? PowerService.hostName + " · callisto" : "callisto"

                onCancelled: PowerState.dismiss()
                onRun: action => {
                    PowerState.dismiss();
                    if (action === "lock")
                        LockState.lock();
                    else
                        PowerService.perform(action);
                }
            }
        }
    }
}
