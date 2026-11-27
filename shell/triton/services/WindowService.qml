pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick

// The open windows, most recently used first, and what can be done to them.
// Shared by the window switcher and the overview.
Singleton {
    id: root

    // Addresses, most recently focused first. Kept as focus moves, so the
    // order is ready the instant Alt+Tab is pressed.
    property var history: []

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const address = Hyprland.activeToplevel?.address;
            if (address)
                root.history = [address].concat(root.history.filter(a => a !== address));
        }
    }

    // Positions, floating state and classes only arrive on request.
    function refresh() {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function appName(appId) {
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.name ?? appId;
    }

    function appIcon(appId) {
        const icon = DesktopEntries.heuristicLookup(appId)?.icon ?? "";
        return icon.startsWith("/") ? "file://" + icon : icon !== "" ? Quickshell.iconPath(icon, true) : "";
    }

    function describe(toplevel) {
        const ipc = toplevel.lastIpcObject;
        const appId = toplevel.wayland?.appId || ipc?.class || "";
        return {
            address: toplevel.address,
            title: toplevel.title || appName(appId),
            appId: appId,
            app: appName(appId),
            icon: appIcon(appId),
            capture: toplevel.wayland,
            workspace: toplevel.workspace?.id ?? 0,
            recent: ipc?.focusHistoryID ?? Number.MAX_SAFE_INTEGER,
            floating: ipc?.floating ?? false,
            aspect: ipc?.size && ipc.size[1] > 0 ? ipc.size[0] / ipc.size[1] : 1.6
        };
    }

    // Special (scratchpad) workspaces have negative ids and stay out.
    readonly property var windows: {
        // What was focused before the shell started is only known to Hyprland.
        const rank = w => {
            const i = history.indexOf(w.address);
            return i < 0 ? history.length + w.recent : i;
        };
        return Hyprland.toplevels.values
            .filter(t => t.address && (t.workspace?.id ?? 1) > 0)
            .map(t => describe(t))
            .sort((a, b) => rank(a) - rank(b));
    }

    Component.onCompleted: refresh()

    function selector(address) {
        return 'window = "address:0x' + address + '"';
    }

    function focus(address) {
        Hyprland.dispatch("hl.dsp.focus({ " + selector(address) + " })");
    }

    function close(address) {
        Hyprland.dispatch("hl.dsp.window.close({ " + selector(address) + " })");
    }

    function toggleFloating(address) {
        Hyprland.dispatch('hl.dsp.window.float({ action = "toggle", ' + selector(address) + " })");
    }

    function move(address, workspace) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + workspace + ", follow = false, "
            + selector(address) + " })");
        refresh();
    }
}
