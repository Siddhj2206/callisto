pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.tokens

// One on-screen display at a time. A new one replaces the old in place and
// restarts the hold. The content stays set while it fades out.
Singleton {
    id: root

    property bool open: false
    property string kind: "volume" // "volume" | "muted" | "brightness" | "micOff"
    property real value: 0

    function show(newKind, newValue) {
        kind = newKind;
        if (newValue !== undefined)
            value = newValue;
        open = true;
        // A muted microphone stays up until it is unmuted.
        if (newKind === "micOff")
            hold.stop();
        else
            hold.restart();
    }

    function dismiss() {
        hold.stop();
        open = false;
    }

    Timer {
        id: hold
        interval: Motion.osdHold
        onTriggered: root.open = false
    }
}
