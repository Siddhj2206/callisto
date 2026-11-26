pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications

// Snapshot wrapper around a live Notification object.
//
// Quickshell Notification objects are destroyed when they expire, are
// dismissed, or are closed by the sending application. Bindings against a
// destroyed object are dangling-reference errors, so this wrapper copies every
// display property the moment the notification arrives and keeps a handle to
// the live object only for dismiss()/expire()/action invocation.
//
// Leaf rule: this type never decides WHERE a notification shows up. The
// Notifications service owns the popup queue and the center list.
QtObject {
    id: root

    // Live notification handle. Becomes stale when the sender closes it;
    // every use is guarded with `notification === null` checks via `alive`.
    property Notification notification: null

    // State
    property bool popup: false
    property bool closed: false

    // Snapshot of display data (immune to the source being destroyed)
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string image: ""
    property real expireTimeout: 0
    property int urgency: NotificationUrgency.Normal
    property bool resident: false
    property bool transient: false
    property list<var> actions: []

    property date time: new Date()

    readonly property bool critical: urgency === NotificationUrgency.Critical
    // Critical notifications ignore expiry (board: "stays until dismissed").
    readonly property int timeoutMs: {
        if (critical)
            return 0;
        if (expireTimeout > 0)
            return expireTimeout * 1000;
        return 6000; // board: "timeout 6 s"
    }

    // Live relative-time label driven by the delegate's clock binding.
    // `now` is passed in by the consumer (SystemClock.date) so nothing here
    // creates its own timer.
    function timeLabel(now: date): string {
        const mins = Math.max(0, Math.floor((now.getTime() - time.getTime()) / 60000));
        if (mins < 1)
            return "now";
        const h = Math.floor(mins / 60);
        if (h >= 1)
            return h + " h";
        return mins + " min";
    }

    function dismissPopup() {
        popup = false;
    }

    function dismiss() {
        closed = true;
        popup = false;
        if (notification !== null) {
            notification.dismiss();
            notification = null;
        }
    }

    function expire() {
        closed = true;
        popup = false;
        if (notification !== null) {
            notification.expire();
            notification = null;
        }
    }

    function invokeAction(index: int) {
        if (notification !== null && index >= 0 && index < actions.length) {
            const action = actions[index];
            if (action && action.invoke)
                action.invoke();
        }
    }
}
