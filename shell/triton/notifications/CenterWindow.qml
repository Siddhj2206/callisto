pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// Notification center surface: right-anchored, full height minus 20px
// margins (Notifications board). Opens from the bar bell; the bell's unread
// dot clears when the center is seen.

PanelWindow {
    id: root

    anchors { top: true; right: true; bottom: true }
    implicitWidth: 440 + 20
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: NotificationState.centerOpen

    NotificationCenter {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 40
        groups: NotificationState.groups
        dndActive: NotificationState.dndActive

        onClearGroup: idx => NotificationState.clearGroup(idx)
        onDndToggled: NotificationState.dndActive = !NotificationState.dndActive
    }

    // Opening the center counts as seeing everything.
    onVisibleChanged: {
        if (visible)
            NotificationState.markAllRead();
    }
}
