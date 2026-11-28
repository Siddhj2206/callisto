pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.tokens

// When the bar is not pinned, this decides whether it is showing. The pointer
// reveals it from the top edge, keeps it while it is on the bar, and it hides
// shortly after leaving. Super+B toggles it. In "auto" it also stays wherever
// no window needs its place (`free`).
Singleton {
    id: root

    property bool revealed: false
    property bool edgeHovered: false
    property bool barHovered: false

    readonly property bool hovered: edgeHovered || barHovered
    readonly property bool held: LauncherState.open || QuickSettingsState.open || NotificationState.centerOpen
        || MediaService.popoverOpen || TrayState.open

    readonly property bool auto: SettingsService.barMode === "auto"

    // Whether the monitor's workspace leaves the top of the screen to the bar.
    // Tiled windows fill the screen; a floating one counts if it reaches up
    // into the strip.
    function free(monitor) {
        const workspace = monitor?.activeWorkspace;
        if (!workspace)
            return false;
        const bottom = monitor.y + Metrics.barTop + Metrics.barHeight;
        return !Hyprland.toplevels.values.some(t => {
            const window = t.workspace === workspace ? t.lastIpcObject : null;
            if (t.workspace !== workspace || window?.hidden)
                return false;
            // One not described yet has only just opened.
            return !window?.at || !window.floating || window.at[1] < bottom;
        });
    }

    // Positions and floating state only arrive on request. Events say when
    // windows come, go and change workspace; nothing says that one was floated,
    // dragged or resized, so look again while one is on a workspace being shown.
    Connections {
        target: Hyprland
        enabled: root.auto
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindowv2", "fullscreen", "workspacev2"].includes(event.name))
                Hyprland.refreshToplevels();
        }
    }
    Timer {
        interval: Motion.barSpacePoll
        repeat: true
        running: root.auto && Hyprland.toplevels.values.some(t => t.workspace?.active)
        onTriggered: Hyprland.refreshToplevels()
    }
    onAutoChanged: if (auto) Hyprland.refreshToplevels()
    Component.onCompleted: Hyprland.refreshToplevels()

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
        if (!SettingsService.revealOnUrgent)
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
        interval: SettingsService.revealDelay
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
