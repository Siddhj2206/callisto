pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// OSD controller state: one at a time, hold 1.2s, key-repeat refreshes.
// Producers (volume keys, brightness, layout switch…) call show() with the
// variant and payload; the window binds to whatever is current. The shape of
// the payload is deliberately loose — the OSD leaf reads what it needs.
//
// Timing per the board: enter spatial fast, hold 1.2 s (re-showing refreshes
// the hold), exit effects default. Mic-off stays until dismissed; battery
// low stays 6 s.

Singleton {
    id: root

    // -1 = hidden; otherwise Osd.Variant.* (kept as int to avoid an import
    // cycle — the window translates).
    property int variant: -1
    property real value: 0
    property string icon: ""
    property bool fillIcon: true
    property string text: ""
    property string subtext: ""
    property string trackTitle: ""
    property string trackArtist: ""
    property string batteryPercentText: ""
    property string batteryTimeText: ""

    readonly property bool visible: variant >= 0

    function show(v, payload) {
        root.variant = v;
        if (payload) {
            for (const k in payload)
                if (k in root)
                    root[k] = payload[k];
        }
        // mic-off stays until dismissed (sticky: false for everything else)
        const sticky = payload && payload.sticky;
        if (!sticky) {
            holdTimer.interval = v === 7 ? 6000 : 1200; // 7 = BatteryLow
            holdTimer.restart();
        } else {
            holdTimer.stop();
        }
    }

    function dismiss() {
        root.variant = -1;
        holdTimer.stop();
    }

    Timer {
        id: holdTimer
        interval: 1200
        onTriggered: root.variant = -1
    }
}
