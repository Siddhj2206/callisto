pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon. History is the server's own tracked list, so an app
// closing or updating a notification shows up by itself; toasts are the ones
// currently asking for attention. Nothing is written to disk.
Singleton {
    id: root

    readonly property int historyLimit: 100
    readonly property bool dndActive: SettingsService.dnd
    property bool centerOpen: false

    // Newest first.
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var toasts: [] // newest first
    // [{ app, items }], the app with the newest notification first.
    readonly property var groups: {
        const byApp = new Map();
        for (const n of list) {
            const app = appOf(n);
            if (!byApp.has(app))
                byApp.set(app, []);
            byApp.get(app).push(n);
        }
        return Array.from(byApp, ([app, items]) => ({ app: app, items: items }));
    }

    property var arrived: ({}) // id -> ms
    property double seenAt: 0
    readonly property int unreadCount: centerOpen ? 0 : list.filter(n => (arrived[n.id] ?? 0) > seenAt).length

    function appOf(n) {
        return n.appName || "App";
    }

    function setDnd(on) {
        SettingsService.set("notifications", "dnd", on);
    }

    function toggle() {
        centerOpen = !centerOpen;
    }

    onCenterOpenChanged: {
        seenAt = Date.now();
        if (centerOpen)
            toasts.slice().forEach(n => hideToast(n));
    }

    // Takes a toast off screen. It stays in the center, unless the sender
    // marked it as not worth keeping.
    function hideToast(n) {
        toasts = toasts.filter(t => t !== n);
        if (n.transient)
            n.expire();
    }

    function dismiss(n) {
        toasts = toasts.filter(t => t !== n);
        n.dismiss();
    }

    function dismissAll(items) {
        items.slice().forEach(n => dismiss(n));
    }

    // Clicking the body: the app's default action, if it offers one.
    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default");
        if (action) {
            toasts = toasts.filter(t => t !== n);
            action.invoke();
        } else {
            dismiss(n);
        }
    }

    function invoke(n, identifier) {
        const action = n.actions.find(a => a.identifier === identifier);
        if (!action)
            return;
        toasts = toasts.filter(t => t !== n);
        action.invoke();
    }

    function reply(n, text) {
        toasts = toasts.filter(t => t !== n);
        n.sendInlineReply(text);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const times = Object.assign({}, root.arrived);
            times[n.id] = Date.now();
            root.arrived = times;
            n.closed.connect(() => root.toasts = root.toasts.filter(t => t !== n));

            // Carried over a shell reload: keep it, don't announce it again.
            if (n.lastGeneration)
                return;
            const critical = n.urgency === NotificationUrgency.Critical;
            if (critical)
                BarState.flashForUrgent();
            if (critical || (!root.dndActive && !root.centerOpen))
                root.toasts = [n, ...root.toasts];
            else if (n.transient)
                n.expire();

            const all = trackedNotifications.values;
            for (let i = 0; i < all.length - root.historyLimit; i++)
                all[i].expire();
        }
    }
}
