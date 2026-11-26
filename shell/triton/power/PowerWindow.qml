pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// Power menu surface: fullscreen overlay capturing all input. Wallpaper blur
// is a compositor effect (hyprland layerrule in production); the menu itself
// provides greeting, segment logic and keyboard interaction.

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "#40000A1E" // rgb(0 10 30 / .25) over whatever is beneath
    visible: PowerState.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    PowerMenu {
        anchors.fill: parent
        focus: root.visible
        greeting: "Good evening"
        uptimeText: ""

        onCancel: PowerState.dismiss()
        onActionTriggered: idx => {
            PowerState.dismiss();
            // Session actions (loginctl/systemctl) arrive with the session
            // service — for now the menu closes and the action is logged.
            console.log("POWER action:", idx);
        }
    }
}
