pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.tokens

// When the bar is not pinned, this decides whether it is showing. The pointer
// reveals it from the top edge, keeps it while it is on the bar, and it hides
// shortly after leaving. Super+B toggles it.
Singleton {
    id: root

    property bool revealed: false
    property bool edgeHovered: false
    property bool barHovered: false

    readonly property bool hovered: edgeHovered || barHovered
    readonly property bool held: LauncherState.open || QuickSettingsState.open || NotificationState.centerOpen

    onHoveredChanged: {
        if (hovered) {
            hideTimer.stop();
            if (!revealed)
                revealTimer.restart();
        } else {
            revealTimer.stop();
            scheduleHide(Motion.barHideDelay);
        }
    }
    onHeldChanged: {
        if (held)
            revealed = true;
        else if (!hovered)
            scheduleHide(Motion.barHideDelay);
    }

    function scheduleHide(delay) {
        hideTimer.interval = delay;
        hideTimer.restart();
    }

    // An urgent notification shows the bar briefly.
    function flashForUrgent() {
        if (!SettingsService.get("shell", "revealOnUrgent", true))
            return;
        revealed = true;
        scheduleHide(Motion.urgentPeek);
    }

    function toggle() {
        hideTimer.stop();
        revealed = !revealed;
    }

    Timer {
        id: revealTimer
        interval: SettingsService.get("shell", "revealDelay", Motion.barRevealDwell)
        onTriggered: root.revealed = true
    }

    Timer {
        id: hideTimer
        onTriggered: {
            if (!root.hovered && !root.held)
                root.revealed = false;
        }
    }
}
