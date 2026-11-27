pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.overview
import qs.tokens

// The overview, one window per screen showing that screen's workspaces; the
// focused one takes the keyboard. Always dark.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window
        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focused: Hyprland.focusedMonitor === monitor

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: OverviewState.open && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        visible: presence.mapped
        mask: OverviewState.open ? null : nothing

        Region { id: nothing }

        // This screen's workspaces in order, and an empty one to drop onto.
        readonly property var ribbons: {
            const all = Hyprland.workspaces.values.filter(w => w.id > 0);
            const windows = WindowService.windows;
            const rows = all.filter(w => w.monitor === monitor).sort((a, b) => a.id - b.id).map(w => ({
                id: w.id,
                active: monitor?.activeWorkspace?.id === w.id,
                windows: windows.filter(x => x.workspace === w.id)
            }));
            let free = 1;
            while (all.some(w => w.id === free))
                free++;
            rows.push({ id: free, active: false, windows: [] });
            return rows;
        }

        readonly property bool open: OverviewState.open
        onOpenChanged: {
            if (!open)
                return;
            WindowService.refresh();
            overview.reset();
            overview.forceActiveFocus();
        }

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            Presence {
                id: presence
                show: window.open
                fromScale: 2 - Metrics.enterScale
                anchors.fill: parent

                OverviewScreen {
                    id: overview
                    anchors.fill: parent
                    focus: true
                    wallpaper: {
                        const path = SettingsService.get("appearance", "wallpaper", "/usr/share/backgrounds/callisto/wallpaper.jpg");
                        return path !== "" ? "file://" + path : "";
                    }
                    ribbons: window.ribbons
                    onActivated: address => {
                        OverviewState.dismiss();
                        WindowService.focus(address);
                    }
                    onWorkspaceRequested: workspace => {
                        OverviewState.dismiss();
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace + " })");
                    }
                    onMoveRequested: (address, workspace) => WindowService.move(address, workspace)
                    onCloseRequested: address => WindowService.close(address)
                    onTyped: text => {
                        OverviewState.dismiss();
                        LauncherState.seed = text;
                        LauncherState.open = true;
                    }
                    onSearchRequested: {
                        OverviewState.dismiss();
                        LauncherState.open = true;
                    }
                    onClosed: OverviewState.dismiss()
                }
            }
        }
    }
}
