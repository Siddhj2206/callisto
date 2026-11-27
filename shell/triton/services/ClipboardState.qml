pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// The clipboard picker's state. History is cliphist's; callisto-clip is the
// one way to read and change it.
Singleton {
    id: root

    property bool open: false
    property var entries: [] // { key, kind, title, detail, path, pinned }
    property bool available: true
    property string selectedKey: ""
    property string selectedText: ""

    // The window that was focused when the picker opened gets the paste.
    property string targetApp: ""
    readonly property var terminals: ["foot", "footclient", "alacritty", "kitty",
        "org.wezfurlong.wezterm", "org.gnome.console", "org.gnome.ptyxis", "com.mitchellh.ghostty"]

    function toggle() {
        if (open) {
            dismiss();
            return;
        }
        targetApp = ToplevelManager.activeToplevel?.appId ?? "";
        selectedKey = "";
        selectedText = "";
        open = true;
        refresh();
    }

    function dismiss() {
        open = false;
    }

    function refresh() {
        change([]);
    }

    // Run a change, if any, then reread the list. One at a time, in order.
    property var queue: []
    function change(command) {
        queue.push(command);
        next();
    }

    function next() {
        if (worker.running || queue.length === 0)
            return;
        const command = queue.shift();
        worker.command = ["sh", "-c", '[ "$#" -eq 0 ] || callisto-clip "$@"; callisto-clip list', "sh", ...command];
        worker.running = true;
    }

    function pin(key, pinned) {
        change([pinned ? "pin" : "unpin", key]);
    }

    function remove(key) {
        change(["delete", key]);
    }

    function wipe() {
        change(["wipe"]);
    }

    function select(key) {
        if (key === selectedKey)
            return;
        selectedKey = key;
        selectedText = "";
        show();
    }

    function show() {
        const entry = entries.find(e => e.key === selectedKey);
        if (shower.running || !entry || entry.kind === "image")
            return;
        shower.key = selectedKey;
        shower.command = ["callisto-clip", "show", selectedKey];
        shower.running = true;
    }

    // Copy, and when `paste` is set, send the paste keys to the window that
    // had focus before the picker, once the picker has let go of the keyboard.
    function use(key, paste) {
        dismiss();
        copier.paste = paste;
        copier.command = ["callisto-clip", "copy", key];
        copier.running = true;
    }

    Process {
        id: worker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.entries = JSON.parse(text);
                    root.available = true;
                } catch (e) {
                    root.entries = [];
                    root.available = false;
                }
            }
        }
        onRunningChanged: {
            if (!running)
                Qt.callLater(root.next);
        }
    }

    Process {
        id: shower
        property string key: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (shower.key === root.selectedKey)
                    root.selectedText = text;
            }
        }
        // The selection may have moved on while this one was being read.
        onRunningChanged: {
            if (!running && key !== root.selectedKey)
                Qt.callLater(root.show);
        }
    }

    Process {
        id: copier
        property bool paste: false
        onExited: code => {
            if (code === 0 && paste)
                keys.restart();
        }
    }

    Timer {
        id: keys
        interval: 150
        onTriggered: {
            // Terminals keep Ctrl+V for themselves.
            const mods = root.terminals.includes(root.targetApp.toLowerCase()) ? "CTRL SHIFT" : "CTRL";
            if (root.targetApp !== "")
                Hyprland.dispatch('hl.dsp.send_shortcut({ mods = "' + mods + '", key = "V" })');
        }
    }
}
