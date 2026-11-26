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

    // The store write goes through sh so directory creation and the write
    // happen in one process — FileView does not create missing directories,
    // and the first-ever save is exactly when the directory doesn't exist.
    //
    // Writes are serialized: only one writer process at a time. Anything
    // that arrives while it's running is held in pendingPayload and flushed
    // when the writer exits — otherwise rapid writes (slider drags) are
    // silently dropped while the store has already moved on.
    property string pendingPayload: ""
    property bool writeDirty: false

    Process {
        id: writeProc
        command: ["sh", "-c", "mkdir -p \"$HOME/.config/callisto\" && cat > \"$HOME/.config/callisto/settings.json\""]
        stdinEnabled: true
        property string payload: ""
        onStarted: {
            // write() before the process exists is silently lost — the write
            // must happen here, once stdin is real.
            write(payload);
            stdinEnabled = false;
        }
        onExited: (code, status) => {
            if (root.writeDirty) {
                // A newer write queued while we were flushing — flush it now.
                root.writeDirty = false;
                writeProc.payload = root.pendingPayload;
                writeProc.stdinEnabled = true;
                writeProc.running = true;
                return;
            }
            // The final write of a burst triggers one apply. Rapid sets are
            // debounced by nature of the write queue: one apply per flush.
            if (!applyProc.running)
                applyProc.running = true;
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
        const payload = JSON.stringify(next, null, 2) + "\n";
        if (writeProc.running) {
            // Writer busy — queue the newest snapshot; it always wins.
            root.pendingPayload = payload;
            root.writeDirty = true;
        } else {
            writeProc.payload = payload;
            writeProc.stdinEnabled = true;
            writeProc.running = true;
        }
    }
}
