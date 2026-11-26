pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// The settings store service: reads and writes ~/.config/callisto/settings.json
// and applies changes through callisto-apply (the theme engine). This is the
// ONLY writer of the store — the contract in docs/design/settings-architecture.md.
//
// Usage from the settings UI:
//   SettingsService.set("appearance", "accent", "haze")
// writes the store and runs the engine in one go.

Singleton {
    id: root

    property var store: ({})
    property bool loaded: false

    FileView {
        id: storeFile
        path: Quickshell.env("HOME") + "/.config/callisto/settings.json"
        watchChanges: true
        atomicWrites: true
        blockLoading: false
        blockWrites: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.store = JSON.parse(text());
                root.loaded = true;
            } catch (e) {
                console.warn("settings: store unparseable:", e);
            }
        }
        onLoadFailed: {
            // No store yet — defaults apply; first set() creates it.
            root.store = ({});
            root.loaded = true;
        }
    }

    Process {
        id: applyProc
        command: ["callisto-apply"]
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("settings: callisto-apply exited", code);
        }
    }

    function get(section, key, fallback) {
        const s = store[section];
        if (s && key in s)
            return s[key];
        return fallback;
    }

    function set(section, key, value) {
        // Mutate a copy so FileView writes the full document.
        const next = JSON.parse(JSON.stringify(store));
        if (!next[section])
            next[section] = {};
        next[section][key] = value;
        root.store = next;
        storeFile.setText(JSON.stringify(next, null, 2));
        if (!applyProc.running)
            applyProc.running = true;
    }
}
