pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import qs
import qs.foundations
import qs.services
import qs.surfaces.bar
import qs.tokens

// One per screen: the bar's window, its reveal behaviour and its data.
Scope {
    id: host

    required property ShellScreen screen

    readonly property string mode: SettingsService.barMode // "auto" | "edge" | "hidden" | "pinned"
    readonly property bool pinned: mode === "pinned"
    // A floating bar leaves for screenshots; a pinned one is part of the screen.
    readonly property bool roomy: mode === "auto" && BarState.free(monitor)
    readonly property bool shown: pinned ? !WallpaperState.open
        : (BarState.revealed || roomy) && !WallpaperState.open && !ScreenshotState.open

    // ---- Compositor ----
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property HyprlandWorkspace workspace: monitor?.activeWorkspace ?? null
    readonly property int highestWorkspace: Hyprland.workspaces.values.reduce((max, ws) => Math.max(max, ws.id), 0)
    readonly property HyprlandToplevel toplevel: {
        const active = Hyprland.activeToplevel;
        return active && active.workspace === workspace ? active : null;
    }
    readonly property string appId: toplevel?.wayland?.appId ?? ""

    // ---- Battery: absent on desktops and VMs ----
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.ready && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : -1
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
    readonly property bool batteryLow: hasBattery && !charging && batteryPercent <= 20

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PanelWindow {
        id: window

        screen: host.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: host.pinned ? Metrics.barHeight : Metrics.barHeight + Metrics.barTop * 2
        exclusiveZone: host.pinned ? Metrics.barHeight : 0
        color: "transparent"
        WlrLayershell.namespace: "triton-glass"
        visible: presence.mapped

        // Floating, only the islands take input; the gap stays clickable.
        mask: host.pinned ? null : islands

        Region {
            id: islands
            Region {
                x: bar.leftItem.x
                y: Metrics.barTop
                width: bar.leftItem.width
                height: Metrics.barHeight
            }
            Region {
                x: bar.centreItem.x
                y: Metrics.barTop
                width: bar.media !== null ? bar.centreItem.width : 0
                height: Metrics.barHeight
            }
            Region {
                x: bar.rightItem.x
                y: Metrics.barTop
                width: bar.rightItem.width
                height: Metrics.barHeight
            }
        }

        Presence {
            id: presence
            show: host.shown
            fromY: host.pinned ? 0 : -(Metrics.barHeight + Metrics.barTop)
            y: host.pinned ? 0 : Metrics.barTop
            width: parent.width
            height: Metrics.barHeight

            Bar {
                id: bar
                width: parent.width
                pinned: host.pinned

                workspaceCount: Math.max(4, host.highestWorkspace)
                activeWorkspace: host.workspace?.id ?? 1

                appName: SettingsService.showWindowTitle && host.appId !== ""
                    ? (DesktopEntries.heuristicLookup(host.appId)?.name ?? host.appId) : ""
                windowTitle: host.toplevel?.title ?? ""

                time: Qt.formatDateTime(clock.date, SettingsService.clock24h ? "HH:mm" : "h:mm AP")
                date: Qt.formatDateTime(clock.date, "ddd d MMM")

                networkGlyph: NetworkService.wired ? Icons.lan
                    : NetworkService.connected ? Icons.wifi : Icons.wifiOff
                volumeGlyph: !AudioService.available ? ""
                    : Icons.volume(AudioService.volume, AudioService.muted)
                batteryPercent: host.batteryPercent
                batteryRing: SettingsService.batteryWavyRing
                batteryGlyph: {
                    if (!host.hasBattery)
                        return "";
                    if (host.charging)
                        return Icons.bolt;
                    if (host.batteryLow)
                        return Icons.batteryAlert;
                    const levels = [Icons.battery0Bar, Icons.battery1Bar, Icons.battery2Bar, Icons.battery3Bar,
                        Icons.battery4Bar, Icons.battery5Bar, Icons.battery6Bar];
                    return levels[Math.max(1, Math.round(host.batteryPercent / 100 * 6))];
                }
                statusState: host.batteryLow ? "urgent"
                    : !NetworkService.online ? "attention" : "ok"

                media: MediaService.present ? MediaService.current : null
                onMediaToggled: MediaService.togglePlaying()
                onMediaNextRequested: MediaService.next()
                onMediaPreviousRequested: MediaService.previous()
                onMediaRequested: MediaService.popoverOpen = !MediaService.popoverOpen

                background: TrayState.items.length > 0
                backgroundOpen: TrayState.open
                onBackgroundRequested: TrayState.toggle()
                micApp: PrivacyService.micApp
                micMuted: PrivacyService.micMuted
                video: PrivacyService.video
                recording: RecordState.recording ? RecordState.elapsed : ""
                onRecordingStopRequested: RecordState.stop()

                unread: NotificationState.unreadCount > 0
                dnd: NotificationState.dndActive

                onHoveredChanged: BarState.barHovered = hovered
                onLauncherRequested: LauncherState.toggle()
                onWorkspaceRequested: number => Hyprland.dispatch("hl.dsp.focus({ workspace = " + number + " })")
                onStatusRequested: QuickSettingsState.toggle()
                onNotificationsRequested: NotificationState.toggle()
                onVolumeStepped: steps => AudioService.stepVolume(steps)
            }
        }
    }

    // The 2px strip along the top edge that wakes the bar.
    PanelWindow {
        screen: host.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 2
        visible: host.mode === "edge" || host.mode === "auto"
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "triton-glass"

        HoverHandler {
            onHoveredChanged: BarState.edgeHovered = hovered
        }
    }
}
