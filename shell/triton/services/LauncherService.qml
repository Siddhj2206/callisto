pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import ".."

// Launcher backend: app search over DesktopEntries, mode derivation from the
// query prefix (= calc, > commands), and launching. The panel stays a leaf —
// everything stateful lives here so the search behaves identically no matter
// how the launcher was opened.
//
// Search is deliberately simple and predictable: lowercase substring match
// over name + genericName + keywords + id, ranked prefix-first. No fuzzy
// magic — a launcher you can't predict is worse than a dumb one.

Singleton {
    id: root

    property string query: ""
    // mode: 0 apps, 1 calc, 2 commands (mirrors LauncherPanel.Mode ordering)
    readonly property int mode: query.startsWith("=") ? 1
                              : query.startsWith(">") ? 2 : 0

    // The searchable corpus, snapshotted as plain objects — the panel binds
    // rows, not desktop entries.
    readonly property var entries: DesktopEntries.applications.values

    function scoreEntry(e, q) {
        const name = (e.name || "").toLowerCase();
        const generic = (e.genericName || "").toLowerCase();
        const id = (e.id || "").toLowerCase();
        const keys = (e.keywords || []).join(" ").toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.includes(q))
            return 80;
        if (generic.includes(q))
            return 60;
        if (keys.includes(q))
            return 50;
        if (id.includes(q))
            return 40;
        return -1;
    }

    // Filtered + ranked apps for the current query. Empty query = everything,
    // alphabetical — the launcher is also the app menu.
    readonly property var matchedApps: {
        const q = root.query.trim().toLowerCase();
        const list = [];
        for (const e of root.entries) {
            if (!e || !e.name)
                continue;
            if (q === "") {
                list.push({ entry: e, score: 1 });
                continue;
            }
            const sc = scoreEntry(e, q);
            if (sc >= 0)
                list.push({ entry: e, score: sc });
        }
        list.sort((a, b) => {
            if (a.score !== b.score)
                return b.score - a.score;
            return (a.entry.name || "").localeCompare(b.entry.name || "");
        });
        return list;
    }

    // Panel row model: label + row entries shaped exactly as LauncherPanel's
    // results contract expects.
    readonly property var results: {
        if (root.mode !== 0)
            return [];
        const rows = [];
        const apps = root.matchedApps;
        if (apps.length === 0) {
            rows.push({ kind: "label", text: "No results" });
            return rows;
        }
        rows.push({ kind: "label", text: root.query.trim() === "" ? "Applications" : "Results" });
        const cap = Math.min(apps.length, 8);
        for (let i = 0; i < cap; i++) {
            const e = apps[i].entry;
            rows.push({
                kind: "row",
                glyph: Icons.apps,
                title: e.name || "",
                subtitle: e.genericName || e.comment || "",
                iconName: e.icon || "",
                tag: "",
                entryIndex: i,
            });
        }
        return rows;
    }

    // Top hit: the best match (or nothing when empty).
    readonly property var topHit: root.matchedApps.length > 0 ? root.matchedApps[0].entry : null

    // Calc mode: a small safe evaluator — digits, operators, parens, dots,
    // percent. No identifiers, no function calls: this is arithmetic, not JS.
    function evalCalc(expr) {
        if (!/^[0-9+\-*/().\s%×÷^]+$/.test(expr))
            return "";
        try {
            const cleaned = expr.replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**").replace(/%/g, "/100");
            const val = Function('"use strict"; return (' + cleaned + ')')();
            if (typeof val !== "number" || !isFinite(val))
                return "";
            // Trim float noise.
            return String(Math.round(val * 1e10) / 1e10);
        } catch (e) {
            return "";
        }
    }

    readonly property string calcResult: root.mode === 1 ? evalCalc(root.query.slice(1)) : ""

    function launch(entry) {
        if (!entry)
            return;
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["foot", "-e"].concat(entry.command),
                workingDirectory: entry.workingDirectory || "",
            });
        } else {
            entry.execute();
        }
    }

    function launchIndex(rowIdx) {
        // Rows carry their own matchedApps index; row 0 is the label.
        const rows = root.results.filter(r => r.kind !== "label");
        if (rowIdx < 0 || rowIdx >= rows.length)
            return false;
        const idx = rows[rowIdx].entryIndex;
        if (idx === undefined || idx >= root.matchedApps.length)
            return false;
        root.launch(root.matchedApps[idx].entry);
        return true;
    }

    function launchTopHit() {
        if (root.topHit) {
            root.launch(root.topHit);
            return true;
        }
        return false;
    }

    // Commands mode: run the shell command after ">".
    function runCommand() {
        const cmd = root.query.slice(1).trim();
        if (cmd !== "")
            Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function activateSelection(rowIdx) {
        if (root.mode === 1) {
            // Calc: copy the result to the clipboard.
            if (root.calcResult !== "")
                Quickshell.execDetached(["sh", "-c", "printf %s " + "'" + root.calcResult.replace(/'/g, "'\\''") + "' | wl-copy"]);
            return true;
        }
        if (root.mode === 2) {
            root.runCommand();
            return true;
        }
        return root.launchIndex(rowIdx);
    }

    function reset() {
        root.query = "";
    }
}
