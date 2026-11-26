pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard panel state + real history. callisto-clipwatch (a session
// autostart) maintains ~/.cache/callisto/clipboard.json; this singleton
// watches it and exposes entries as picker rows. Paste re-injects the entry
// through wl-copy — the compositor then delivers it to the focused window.

Singleton {
    id: root

    property bool open: false
    property var entries: []

    function toggle() {
        open = !open;
    }

    function dismiss() {
        open = false;
    }

    function paste(entry) {
        if (!entry)
            return;
        pasteProc.payload = entry.text;
        pasteProc.stdinEnabled = true;
        pasteProc.running = true;
        dismiss();
    }

    function pin(entry, pinned) {
        const es = root.entries.slice();
        const i = es.findIndex(e => e.text === entry.text);
        if (i < 0)
            return;
        es[i] = Object.assign({}, es[i], { pinned: pinned });
        writeProc.payload = JSON.stringify(es);
        writeProc.stdinEnabled = true;
        writeProc.running = true;
    }

    FileView {
        path: Quickshell.env("XDG_CACHE_HOME") !== ""
            ? Quickshell.env("XDG_CACHE_HOME") + "/callisto/clipboard.json"
            : Quickshell.env("HOME") + "/.cache/callisto/clipboard.json"
        watchChanges: true
        blockLoading: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.entries = JSON.parse(text());
            } catch (e) {
                root.entries = [];
            }
        }
        onLoadFailed: root.entries = []
    }

    Process {
        id: pasteProc
        command: ["wl-copy"]
        property string payload: ""
        onStarted: {
            write(payload);
            stdinEnabled = false;
        }
    }

    Process {
        id: writeProc
        command: ["sh", "-c", "mkdir -p \"$HOME/.cache/callisto\" && cat > \"$HOME/.cache/callisto/clipboard.json\""]
        property string payload: ""
        onStarted: {
            write(payload);
            stdinEnabled = false;
        }
    }
}
