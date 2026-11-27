pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs

// Launcher search: applications, open windows, shell commands and arithmetic.
// Ranking is how well the text matches, then how often and how recently the
// app was picked.
Singleton {
    id: root

    property string query: ""
    property string filter: "all" // "all" | "apps" | "windows"

    readonly property string mode: query.startsWith("=") || /^\s*[(\-]?\d[\d\s.()]*[+\-*\/^%×÷]/.test(query) ? "calc"
        : query.startsWith(">") ? "commands" : "apps"
    readonly property string term: (mode === "commands" ? query.slice(1) : query).trim().toLowerCase()

    function reset() {
        query = "";
        filter = "all";
    }

    // ---- usage memory -------------------------------------------------------
    property var usage: ({}) // desktop id -> { count, last }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                console.warn("launcher: usage file unreadable, starting over");
            }
        }
    }

    function remember(id) {
        const next = Object.assign({}, usage);
        next[id] = { count: (next[id]?.count ?? 0) + 1, last: Date.now() };
        usage = next;
        usageFile.setText(JSON.stringify(next));
    }

    function habit(id) {
        const seen = usage[id];
        if (!seen)
            return 0;
        const days = (Date.now() - seen.last) / 86400000;
        return Math.min(seen.count, 10) * (days < 4 ? 150 : days < 14 ? 100 : days < 60 ? 60 : 20);
    }

    // ---- matching -----------------------------------------------------------
    // 0 is no match.
    function match(q, name, extra) {
        const n = name.toLowerCase();
        if (n === q)
            return 10000;
        if (n.startsWith(q))
            return 5000;
        if (n.split(/[\s\-_.]+/).some(word => word.startsWith(q)))
            return 3000;
        if (n.includes(q))
            return 1500;
        const e = extra.toLowerCase();
        if (e.split(/[\s\-_.;]+/).some(word => word.startsWith(q)))
            return 700;
        if (e.includes(q))
            return 400;
        // Letters in order ("ffx" finds Firefox), from the first letter on.
        if (q.length < 2 || n[0] !== q[0])
            return 0;
        let at = 0;
        for (const c of q) {
            at = n.indexOf(c, at) + 1;
            if (at === 0)
                return 0;
        }
        return 100;
    }

    // Debian's Flatpak exports can prefix the runtime version to a name.
    function cleanName(name) {
        return name.replace(/^\([\d.]+ Flatpak\)\s*/, "");
    }

    function iconPath(name) {
        if (!name)
            return "";
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true);
    }

    function appRow(entry) {
        const extra = entry.actions.filter(a => a.id === "new-window" || a.id === "new-private-window");
        return {
            key: "app:" + entry.id,
            section: "Apps",
            title: cleanName(entry.name),
            subtitle: entry.genericName || entry.comment || "",
            icon: iconPath(entry.icon),
            glyph: Icons.apps,
            actions: [{ id: "", label: "Open" }].concat(entry.actions.map(a => ({ id: a.id, label: a.name }))),
            quick: extra.length > 0 ? { id: extra[0].id, label: extra[0].name } : null,
            run: action => root.launch(entry, action)
        };
    }

    readonly property var apps: {
        const q = term;
        const found = [];
        for (const entry of DesktopEntries.applications.values) {
            if (!entry.name || entry.noDisplay)
                continue;
            const name = cleanName(entry.name);
            const score = q === "" ? 1 : match(q, name, [entry.genericName, entry.id, entry.keywords.join(" ")].join(" "));
            if (score > 0)
                found.push({ entry: entry, name: name, score: score + habit(entry.id) });
        }
        found.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));
        return found.map(f => appRow(f.entry));
    }

    readonly property var windows: {
        const q = term;
        return ToplevelManager.toplevels.values
            .filter(w => w.title && (q === "" || match(q, w.title, w.appId) > 0))
            .map((w, i) => ({
                key: "window:" + i,
                section: "Windows",
                title: w.title,
                subtitle: w.appId,
                icon: root.iconPath(DesktopEntries.heuristicLookup(w.appId)?.icon),
                glyph: Icons.apps,
                actions: [{ id: "", label: "Switch to" }, { id: "close", label: "Close" }],
                quick: { id: "close", label: "Close" },
                run: action => action === "close" ? w.close() : w.activate()
            }));
    }

    // ---- commands -----------------------------------------------------------
    function command(key, glyph, title, subtitle, run) {
        return { key: "command:" + key, section: "Commands", title: title, subtitle: subtitle, icon: "", glyph: glyph,
            actions: [{ id: "", label: "Run" }], quick: null, run: run };
    }

    readonly property var commands: {
        const night = SettingsService.nightLight;
        const dark = SettingsService.appearanceMode === "dark";
        const state = on => on ? "Currently on" : "Currently off";
        const all = [
            // Titles stay put whatever the state, so the same words find them.
            command("style", Icons.darkMode, "Toggle dark style", state(dark),
                () => SettingsService.set("appearance", "mode", dark ? "light" : "dark")),
            command("dnd", Icons.bedtime, "Toggle Do Not Disturb", state(NotificationState.dndActive),
                () => NotificationState.setDnd(!NotificationState.dndActive)),
            command("night", Icons.nightlight, "Toggle night light", state(night),
                () => SettingsService.set("display", "nightLight", !night)),
            command("wallpaper", Icons.wallpaper, "Change wallpaper", "Appearance", () => WallpaperState.show()),
            command("settings", Icons.settings, "Open Settings", "System", () => SettingsAppState.show()),
            command("lock", Icons.lock, "Lock the screen", "Session", () => LockState.lock()),
            command("power", Icons.powerSettingsNew, "Power off, restart or log out", "Session", () => PowerState.open = true)
        ];
        const q = term;
        const found = q === "" ? all : all.filter(c => match(q, c.title, c.subtitle) > 0);
        if (mode === "commands" && q !== "") {
            const line = query.slice(1).trim();
            found.push(command("shell", Icons.terminal, line, "Run in a shell",
                () => Quickshell.execDetached(["uwsm", "app", "--", "sh", "-c", line])));
        }
        return found;
    }

    // ---- arithmetic ---------------------------------------------------------
    readonly property string expression: mode === "calc" ? query.replace(/^=/, "").trim() : ""
    readonly property string calcResult: {
        // Digits and operators only, so evaluating it cannot reach anything.
        if (!/^[0-9+\-*\/().\s%×÷^]+$/.test(expression))
            return "";
        try {
            const value = Function('"use strict"; return (' + expression.replace(/×/g, "*").replace(/÷/g, "/")
                .replace(/\^/g, "**").replace(/%/g, "/100") + ')')();
            return typeof value === "number" && isFinite(value) ? String(Math.round(value * 1e10) / 1e10) : "";
        } catch (e) {
            return "";
        }
    }

    function copyResult() {
        if (calcResult !== "")
            Quickshell.clipboardText = calcResult;
    }

    // ---- results ------------------------------------------------------------
    // Best match first; the rest keep their sections.
    readonly property var results: {
        if (mode === "calc")
            return [];
        if (mode === "commands")
            return commands;
        let rows = [];
        if (filter !== "windows")
            rows = rows.concat(term === "" || filter === "apps" ? apps : apps.slice(0, 6));
        if (filter === "windows" || (filter === "all" && term !== ""))
            rows = rows.concat(windows);
        if (filter === "all" && term !== "")
            rows = rows.concat(commands);
        return rows;
    }

    function launch(entry, actionId) {
        remember(entry.id);
        const action = entry.actions.find(a => a.id === actionId);
        // uwsm gives the app its own systemd scope, outside the shell's.
        let command = action ? action.command : entry.command;
        if (entry.runInTerminal)
            command = ["foot", "-e"].concat(command);
        Quickshell.execDetached({
            command: ["uwsm", "app", "-a", entry.id, "--"].concat(command),
            workingDirectory: entry.workingDirectory || Quickshell.env("HOME")
        });
    }
}
