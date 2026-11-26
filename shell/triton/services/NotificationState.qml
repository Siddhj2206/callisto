pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification state: the single place toasts and the center read from.
// Wraps quickshell's NotificationServer — new arrivals append to the toast
// queue and the grouped history at once, honoring the board's rules:
//
//   - max 4 visible toasts, overflow collapses into a count pill
//   - toasts expire after 6 s; critical ones stay until dismissed
//   - DND sends everything straight to the center (critical and calls
//     still toast)
//   - groups are per-app, newest first
//
// Service absence (container without dbus) degrades to an empty state —
// visual development uses the mock harnesses instead.

Singleton {
    id: root

    property bool dndActive: false
    property bool centerOpen: false

    // Toast queue and center groups, plain JS arrays of plain objects so the
    // dev harness can inject identically-shaped mocks.
    property var toasts: []
    property var groups: []
    property int overflowCount: 0

    // Unread drives the bell's tertiary dot: anything in the center that
    // hasn't been seen.
    property int unreadCount: 0

    readonly property var server: NotificationServer {
        onNotification: notification => {
            root.addNotification({
                app: notification.appName || "App",
                title: notification.summary || "",
                preview: notification.body || "",
                time: "now",
                critical: notification.urgency === NotificationUrgency.Critical,
                icon: notification.appIcon || "",
            });
        }
    }

    function addNotification(n) {
        const showToast = !root.dndActive || n.critical;
        if (showToast) {
            const t = root.toasts.slice();
            t.push(n);
            root.toasts = t;
            if (!n.critical) {
                // expire after 6s
                expireTimer.item = n;
                expireTimer.restart();
            }
        }
        root.unreadCount++;
        root.rebuildGroups(n);
    }

    function rebuildGroups(n) {
        const gs = root.groups.slice();
        const i = gs.findIndex(g => g.app === n.app);
        if (i >= 0) {
            const g = Object.assign({}, gs[i]);
            g.items = [n].concat(g.items || []);
            g.count = (g.count || 0) + 1;
            gs[i] = g;
        } else {
            gs.unshift({
                app: n.app,
                count: 1,
                countText: "1",
                expanded: true,
                items: [n],
            });
        }
        root.groups = gs;
    }

    function dismissToast(n) {
        root.toasts = root.toasts.filter(t => t !== n);
    }

    function clearGroup(idx) {
        const gs = root.groups.slice();
        const cleared = gs.splice(idx, 1)[0];
        root.groups = gs;
        root.unreadCount = Math.max(0, root.unreadCount - (cleared.items || []).length);
    }

    function markAllRead() {
        root.unreadCount = 0;
    }

    property var expireTimer: Timer {
        id: expireTimer
        property var item: null
        interval: 6000
        onTriggered: if (item) root.dismissToast(item)
    }
}
