pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
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
            // PowerMenu order: lock, sleep, logout, restart, shutdown.
            // Logout goes through uwsm stop — the compositor must never be
            // killed or exited directly (units tear down in the wrong order).
            const cmds = [
                ["loginctl", "lock-session"],
                ["systemctl", "suspend"],
                ["uwsm", "stop"],
                ["systemctl", "reboot"],
                ["systemctl", "poweroff"],
            ];
            if (idx >= 0 && idx < cmds.length)
                Quickshell.execDetached(cmds[idx]);
        }
    }
}
