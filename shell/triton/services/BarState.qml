pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Bar reveal state for hidden/edge autohide modes. In pinned mode the bar
// ignores this entirely. Revealing also happens automatically while the
// launcher is open — the bar is the launcher's visual context.

Singleton {
    id: root

    property bool revealed: false

    // Hover-driven reveal with a hide delay — without the delay the bar
    // vanishes the instant the pointer slips one pixel off the sensor.
    property bool hovering: false
    onHoveringChanged: {
        if (hovering) {
            hideTimer.stop();
            // Reveal delay: the pointer must rest at the edge — bumping
            // through it must not flash the bar.
            revealTimer.interval = SettingsService.get("shell", "revealDelay", 300);
            revealTimer.restart();
        } else {
            revealTimer.stop();
            hideTimer.restart();
        }
    }

    Timer {
        id: revealTimer
        interval: 300
        onTriggered: root.revealed = true
    }

    // Urgent-notification peek: 4 seconds, per the BarShell settings copy.
    function flashForUrgent() {
        if (!SettingsService.get("shell", "revealOnUrgent", true))
            return;
        revealed = true;
        hideTimer.interval = 4000;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: {
            interval = 1200; // restore after an urgent flash
            if (!root.hovering && !LauncherState.open)
                root.revealed = false;
        }
    }

    function toggle() {
        revealed = !revealed;
    }
}
