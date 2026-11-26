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
                time: Qt.formatTime(new Date(), "h:mm ap"),
                critical: notification.urgency === NotificationUrgency.Critical,
                icon: notification.appIcon || "",
            });
        }
    }

    function addNotification(n) {
        const showToast = !root.dndActive || n.critical;
        if (showToast) {
            // Stamp expiry at insertion — every toast expires independently
            // (a single restarted timer only ever expired the newest one).
            if (!n.critical)
                n.expiresAt = Date.now() + 6000;
            const t = root.toasts.slice();
            t.push(n);
            root.toasts = t;
            sweepTimer.running = true;
        }
        root.unreadCount++;
        root.rebuildGroups(n);
    }

    function rebuildGroups(n) {
        const gs = root.groups.slice();
        const i = gs.findIndex(g => g.app === n.app);
        if (i >= 0) {
            const g = Object.assign({}, gs[i]);
            // Cap per-group history — an unbounded array behind a Repeater is
            // a memory leak you can watch grow in real time.
            g.items = [n].concat(g.items || []).slice(0, 20);
            g.count = (g.count || 0) + 1;
            g.countText = String(g.count);
            // Move the active group to the top.
            gs.splice(i, 1);
            gs.unshift(g);
        } else {
            gs.unshift({
                app: n.app,
                count: 1,
                countText: "1",
                expanded: true,
                items: [n],
            });
        }
        // Cap total groups too.
        root.groups = gs.slice(0, 10);
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

    // One slow sweep drops everything past its own expiry timestamp —
    // expiry is per-toast, the timer is just the garbage collector.
    property var sweepTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: {
            const now = Date.now();
            const alive = root.toasts.filter(t => t.critical || !t.expiresAt || t.expiresAt > now);
            if (alive.length !== root.toasts.length)
                root.toasts = alive;
            if (alive.length === 0)
                running = false;
        }
    }

    // Center group expansion: the chevron in NotificationCenter flips this.
    function toggleGroup(idx) {
        const gs = root.groups.slice();
        const g = Object.assign({}, gs[idx]);
        g.expanded = !g.expanded;
        gs[idx] = g;
        root.groups = gs;
    }

    // Uniform surface API — every state singleton answers toggle().
    function toggle() {
        root.centerOpen = !root.centerOpen;
    }
}
