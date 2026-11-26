pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Overview backend: real Hyprland workspaces and windows. The generic
// ToplevelManager covers the window list compositor-agnostically; workspace
// identity is hyprland-specific (sway harness degrades to one workspace).

Singleton {
    id: root

    readonly property bool hyprlandActive: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""

    // Workspace rows shaped for the overview leaf.
    readonly property var workspaces: {
        if (!hyprlandActive)
            return [{ num: 1, name: "Work", count: 0, active: true }];
        const rows = [];
        for (const ws of Hyprland.workspaces.values) {
            rows.push({
                num: ws.id,
                name: ws.name || String(ws.id),
                count: ws.toplevels ? ws.toplevels.values.length : 0,
                active: Hyprland.focusedWorkspace === ws,
                wsObj: ws,
            });
        }
        return rows;
    }

    // Windows per workspace as ribbons.
    readonly property var ribbons: {
        if (!hyprlandActive)
            return [{ windows: [] }];
        const out = [];
        for (const ws of Hyprland.workspaces.values) {
            const wins = [];
            if (ws.toplevels) {
                for (const t of ws.toplevels.values) {
                    wins.push({
                        app: t.appId || t.title || "",
                        title: t.title || "",
                        focused: Hyprland.activeToplevel === t,
                        floating: false,
                        toplevelObj: t,
                    });
                }
            }
            out.push({ workspace: ws.id, windows: wins });
        }
        return out;
    }

    function activateWindow(win) {
        if (win && win.toplevelObj)
            win.toplevelObj.activate();
    }
}
