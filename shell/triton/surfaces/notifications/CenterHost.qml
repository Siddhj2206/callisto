pragma ComponentBehavior: Bound

import QtQuick
import qs.patterns
import qs.services
import qs.tokens

// The notification center, wired to the daemon.
Popover {
    id: root

    open: NotificationState.centerOpen
    panelWidth: Metrics.centerWidth
    panelHeight: height // as tall as the screen allows
    panelRadius: Metrics.radiusPanelS
    onDismissed: NotificationState.centerOpen = false
    onBack: NotificationState.centerOpen = false

    NotificationCenter {
        anchors.fill: parent
        groups: NotificationState.groups
        describe: n => NotificationEntry.of(n)
        dnd: NotificationState.dndActive
        onDndToggled: NotificationState.setDnd(!NotificationState.dndActive)
        onCleared: items => NotificationState.dismissAll(items)
        onActivated: n => NotificationState.activate(n)
        onDismissed: n => NotificationState.dismiss(n)
        onActionTriggered: (n, id) => NotificationState.invoke(n, id)
        onReplied: (n, text) => NotificationState.reply(n, text)
    }
}
