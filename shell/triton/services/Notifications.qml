pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../notifications"

// Triton notification service — the shell's notification daemon (replaces mako).
//
// Owns a Quickshell NotificationServer, snapshots every incoming notification
// into a NotificationItem wrapper (safe to bind after the source closes), and
// manages:
//   - list       — everything still relevant, for the notification center
//   - popupQueue — notifications currently asking for a toast, newest last
//   - doNotDisturb — toasts suppressed, everything still lands in the center
//
// Timeout of individual toasts is owned by the popup delegate (hover pauses
// it, per the board); the service only manages membership. Popup delegates
// call item.dismissPopup() or dismiss()/expire().
//
// Per the board: critical notifications bypass DND and never time out.
Singleton {
    id: root

    // All tracked notifications, newest first. Non-transient ones persist here
    // for the notification center even after their popup times out.
    property list<NotificationItem> list: []

    // Notifications currently wanting a toast. Newest LAST so delegates can
    // append. The popup surface shows at most `maxPopups`; the rest collapse
    // into the "N more" pill.
    property list<NotificationItem> popupQueue: []

    readonly property int maxPopups: 4

    // Count of queued toasts beyond what the surface shows at once.
    readonly property int overflowCount: Math.max(0, popupQueue.length - maxPopups)

    property bool doNotDisturb: false

    function dismissPopup(item: NotificationItem) {
        item.popup = false;
        syncPopupQueue();
    }

    function dismiss(item: NotificationItem) {
        item.dismiss();
        syncPopupQueue();
        prune();
    }

    // Drop the popup (timeout) but keep it in the center.
    function expirePopup(item: NotificationItem) {
        if (!item.popup)
            return;
        item.popup = false;
        // Tell the sender it timed out if nothing persists it.
        if (item.transient)
            item.expire();
        syncPopupQueue();
    }

    function clearAll() {
        for (const item of root.list.slice())
            item.dismiss();
        root.list = [];
        root.popupQueue = [];
    }

    function clearApp(appName: string) {
        for (const item of root.list.slice()) {
            if (item.appName === appName)
                item.dismiss();
        }
        prune();
        syncPopupQueue();
    }

    // Remove closed items from the center list.
    function prune() {
        root.list = root.list.filter(item => !item.closed);
    }

    function syncPopupQueue() {
        root.popupQueue = root.popupQueue.filter(item => item.popup && !item.closed);
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false
        persistenceSupported: true

        onNotification: notification => {
            // If the shell doesn't track it, the object is destroyed
            // immediately — we must track everything we snapshot.
            notification.tracked = true;

            const item = notifComponent.createObject(null, {
                "notification": notification,
                "appName": notification.appName,
                "summary": notification.summary,
                "body": notification.body,
                "appIcon": notification.appIcon,
                "image": notification.image,
                "expireTimeout": notification.expireTimeout,
                "urgency": notification.urgency,
                "resident": notification.resident,
                "transient": notification.transient,
                "actions": notification.actions,
                "time": new Date()
            });

            // A popup is wanted unless DND is on. Criticals always toast.
            item.popup = !root.doNotDisturb || item.critical;

            root.list = [item].concat(root.list);
            if (item.popup)
                root.popupQueue = root.popupQueue.concat([item]);

            // If the source object dies behind our back, the snapshot keeps
            // the center correct; the popup just stops being interactive.
            notification.dropped.connect(() => {
                item.notification = null;
            });
        }
    }

    Component {
        id: notifComponent

        NotificationItem {}
    }
}
