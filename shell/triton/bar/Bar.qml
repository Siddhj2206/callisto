pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import "../components"
import "../services"
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import ".."

// The bar in its revealed state (BarStates board, state 2): two floating
// Glass islands on a transparent full-width strip. The window reserves
// nothing (exclusiveZone 0) — the islands cover what is under them and the
// gap between them leaves the window visible.
//
// This component is the container: it owns the service bindings (Hyprland,
// Pipewire, UPower). Leaf components receive state as plain properties.

PanelWindow {
    id: root

    required property ShellScreen screen

    // ---- Service bindings (owned here, pushed down as plain state) ----

    // Workspaces: event-driven, never polled. `monitorFor` returns a stub
    // object even when Hyprland's IPC is absent, so the liveness check looks
    // at whether the monitor actually has data: with no IPC, activeWorkspace
    // and focusedMonitor both stay null and the pills render inert instead of
    // dispatching into the void.
    readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screen)
    readonly property int activeWorkspaceId: hyprMonitor?.activeWorkspace?.id ?? 0
    readonly property bool hyprlandLive: (hyprMonitor?.activeWorkspace ?? null) !== null
        || Hyprland.focusedMonitor !== null

    function switchWorkspace(id) {
        if (hyprlandLive)
            Hyprland.dispatch("workspace " + id);
    }

    // Active window title for the center island.
    readonly property string activeWindowTitle: Hyprland.activeToplevel?.title ?? ""
    readonly property bool showWindowTitle: SettingsService.get("shell", "showWindowTitle", true)

    // Volume: Pipewire default sink. PwObjectTracker is required before the
    // node's audio properties are valid.
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property bool hasSink: root.sink?.audio !== null && root.sink?.audio !== undefined
    readonly property real volume: hasSink ? root.sink.audio.volume : 0
    readonly property bool muted: hasSink ? root.sink.audio.muted : false

    function adjustVolume(delta) {
        if (!hasSink)
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
    }

    function toggleMute() {
        if (hasSink)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    readonly property string volumeGlyph: {
        if (!hasSink)
            return "";
        if (root.muted)
            return Icons.volumeOff;
        return root.volume < 0.33 ? Icons.volumeDown : Icons.volumeUp;
    }

    // Battery: UPower display device. No battery (VMs, desktops) means the
    // readout disappears entirely — never a placeholder.
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: root.battery !== null
        && root.battery !== undefined
        && root.battery.ready
        && root.battery.isLaptopBattery
    readonly property real batteryPercent: hasBattery ? Math.round(root.battery.percentage * 100) : 0
    readonly property bool batteryCharging: hasBattery && root.battery.state === UPowerDeviceState.Charging

    readonly property string batteryGlyph: {
        if (!hasBattery)
            return "";
        // Per BarStates board §5: bolt while charging, battery_alert when
        // low, else the stepped bar fill.
        if (root.batteryCharging)
            return Icons.bolt;
        if (root.batteryPercent <= 20)
            return Icons.batteryAlert;
        const bars = [Icons.battery0Bar, Icons.battery1Bar, Icons.battery2Bar,
                      Icons.battery3Bar, Icons.battery4Bar, Icons.battery5Bar,
                      Icons.battery6Bar];
        const step = Math.max(1, Math.round(root.batteryPercent / 100 * 6));
        return bars[step];
    }

    // Store-driven visibility: pinned shows always, hidden only on demand,
    // edge reveals when the pointer rests at the top edge (v0.1: hidden and
    // edge both start hidden; edge support lands with the pointer sensor).
    readonly property string barMode: SettingsService.get("shell", "barMode", "pinned")
    visible: (barMode === "pinned" || BarState.revealed || LauncherState.open) && !WallpaperState.open

    anchors {
        top: true
        left: true
        right: true
    }

    // Board values: islands sit 8px below the top edge and are 56px tall.
    // 8 is Theme.space[1]; the 16px screen-edge margins are Theme.space[3].
    margins.top: Theme.space[1]
    implicitHeight: Theme.barHeight + Theme.space[1]

    exclusiveZone: 0
    color: "transparent"

    // ---- Left island: wave launcher + workspace pills ----
    Island {
        id: leftIsland
        anchors.left: parent.left
        anchors.leftMargin: Theme.space[3]
        anchors.top: parent.top

        WaveButton {
            onClicked: LauncherState.toggle()
        }

        // 8px gap between the wave and the first pill, per the board markup
        // (`<span style="width:8px">` after the wave — Theme.space[1]).
        Item { width: Theme.space[1]; height: 1 }

        Repeater {
            model: 5
            WorkspacePill {
                required property int index
                ws: index + 1
                active: root.activeWorkspaceId === index + 1
                live: root.hyprlandLive
                onClicked: () => root.switchWorkspace(index + 1)
            }
        }
    }

    // ---- Center island: active window title (store-gated) ----
    Island {
        visible: root.showWindowTitle && root.activeWindowTitle !== ""
        anchors.centerIn: parent
        anchors.top: parent.top
        anchors.horizontalCenterOffset: 0

        TritonText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.activeWindowTitle.length > 48
                ? root.activeWindowTitle.substring(0, 46) + "…"
                : root.activeWindowTitle
            font.pixelSize: 14
            weight: TritonText.Weight.Medium
            color: Theme.onsurface
            elide: Text.ElideRight
        }
    }

    // ---- Right island: clock, status group, bell ----
    Island {
        id: rightIsland
        anchors.right: parent.right
        anchors.rightMargin: Theme.space[3]
        anchors.top: parent.top

        Clock {}

        StatusGroup {
            wifiGlyph: Icons.wifi
            volumeGlyph: root.volumeGlyph
            batteryGlyph: root.batteryGlyph
            batteryPercent: root.batteryPercent
            onVolumeScrolled: delta => root.adjustVolume(delta)
            onVolumeClicked: () => QuickSettingsState.toggle()
            onClicked: () => QuickSettingsState.toggle()
        }

        BellButton {
            hasUnread: NotificationState.unreadCount > 0
            onClicked: NotificationState.centerOpen = !NotificationState.centerOpen
        }
    }
}
