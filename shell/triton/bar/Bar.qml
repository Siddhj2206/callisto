pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
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
// Pipewire, UPower). Leaf components receive state as required properties.

PanelWindow {
    id: root

    required property ShellScreen screen

    // ---- Service bindings (owned here, pushed down as plain state) ----

    // Workspaces: event-driven, never polled. `monitorFor` returns a stub
    // object even when Hyprland's IPC is absent (verified on niri), so the
    // liveness check looks at whether the monitor actually has data: with no
    // IPC, activeWorkspace and focusedMonitor both stay null and the pills
    // render inert instead of dispatching into the void.
    readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screen)
    readonly property int activeWorkspaceId: hyprMonitor?.activeWorkspace?.id ?? 0
    readonly property bool hyprlandLive: (hyprMonitor?.activeWorkspace ?? null) !== null
        || Hyprland.focusedMonitor !== null

    function switchWorkspace(id) {
        if (hyprlandLive)
            Hyprland.dispatch("workspace " + id);
    }

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

    readonly property string volumeIcon: {
        if (!hasSink)
            return "";
        if (root.muted)
            return "volume_off";
        // Icon steps: the subset has volume_down and volume_up; 1/3 is the
        // conventional split, no board guidance here.
        return root.volume < 0.33 ? "volume_down" : "volume_up";
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

    readonly property string batteryIcon: {
        if (!hasBattery)
            return "";
        // Icon choice per BarStates board §5: bolt while charging,
        // battery_alert when low, else the stepped bar fill. The 20% low
        // threshold matches the board's 14%-low example being well under the
        // normal 82% case; no exact cutoff is specified on the board.
        if (root.batteryCharging)
            return "bolt";
        if (root.batteryPercent <= 20)
            return "battery_alert";
        const step = Math.round(root.batteryPercent / 100 * 6);
        return "battery_" + Math.max(1, step) + "_bar";
    }

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
            onClicked: () => {
                // Launcher is not built yet; wiring arrives with the launcher module.
            }
        }

        // 8px gap between the wave and the first pill, per the board markup
        // (`<span style="width:8px">` after the wave — Theme.space[1]).
        Item { width: Theme.space[1]; height: 1 }

        WorkspacePill {
            index: 1
            active: root.activeWorkspaceId === 1
            live: root.hyprlandLive
            onClicked: () => root.switchWorkspace(1)
        }
        WorkspacePill {
            index: 2
            active: root.activeWorkspaceId === 2
            live: root.hyprlandLive
            onClicked: () => root.switchWorkspace(2)
        }
        WorkspacePill {
            index: 3
            active: root.activeWorkspaceId === 3
            live: root.hyprlandLive
            onClicked: () => root.switchWorkspace(3)
        }
        WorkspacePill {
            index: 4
            active: root.activeWorkspaceId === 4
            live: root.hyprlandLive
            onClicked: () => root.switchWorkspace(4)
        }
        WorkspacePill {
            index: 5
            active: root.activeWorkspaceId === 5
            live: root.hyprlandLive
            onClicked: () => root.switchWorkspace(5)
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
            wifiIcon: "wifi"
            volumeIcon: root.volumeIcon
            batteryIcon: root.batteryIcon
            batteryPercent: root.batteryPercent
            onVolumeScrolled: delta => root.adjustVolume(delta)
            onVolumeClicked: () => root.toggleMute()
        }

        BellButton {}
    }
}
