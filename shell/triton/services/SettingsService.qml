pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// The settings store: reads ~/.config/callisto/settings.json and sends changes
// to callisto-settingsd, its only writer, which also compiles them.
// See docs/design/settings-architecture.md.
//
//   SettingsService.set("appearance", "accent", "haze")

Singleton {
    id: root

    property var store: ({})
    property bool loaded: false
    // Changes the daemon has not taken yet, newest value per key.
    property var pending: ({})

    FileView {
        path: Quickshell.env("HOME") + "/.config/callisto/settings.json"
        watchChanges: true
        blockLoading: false
        onFileChanged: reload()
        onLoaded: {
            try {
                // What is still on its way wins over what is on disk.
                root.store = root.merged(JSON.parse(text()), root.pending);
                root.loaded = true;
            } catch (e) {
                console.warn("settings: store unparseable:", e);
            }
        }
        onLoadFailed: root.loaded = true // no store yet: defaults apply
    }

    // A Quickshell Socket that failed to connect never tries again, so each
    // attempt gets a new one.
    property var link: null
    property bool unreachable: false // warned once until it comes back

    Component {
        id: linkComponent

        Socket {
            path: Quickshell.env("XDG_RUNTIME_DIR") + "/callisto/settingsd.sock"
            onConnectedChanged: {
                if (connected) {
                    root.unreachable = false;
                    root.flush();
                } else {
                    root.drop(this);
                }
            }
            // 1 is PeerClosedError (no QML name): the daemon restarting.
            onError: error => {
                if (error !== 1 && !root.unreachable) {
                    root.unreachable = true;
                    console.warn("settings: cannot reach callisto-settingsd, socket error", error);
                }
                root.drop(this);
            }
            parser: SplitParser {
                onRead: line => {
                    if (!JSON.parse(line).ok)
                        console.warn("settings: refused:", line);
                }
            }
        }
    }

    Timer {
        id: retry
        interval: 1000
        onTriggered: root.flush()
    }

    function drop(socket) {
        if (link !== socket)
            return;
        link = null;
        socket.destroy();
        if (Object.keys(pending).length > 0)
            retry.restart();
    }

    // A slider drag sends one value per interval, not one per pixel.
    Timer {
        id: sender
        interval: 50
        onTriggered: root.flush()
    }

    function merged(base, changes) {
        const next = JSON.parse(JSON.stringify(base));
        for (const key in changes) {
            const [section, name] = key.split(".");
            if (!next[section])
                next[section] = {};
            next[section][name] = changes[key];
        }
        return next;
    }

    function flush() {
        if (Object.keys(pending).length === 0)
            return;
        if (!link) {
            link = linkComponent.createObject(root);
            link.connected = true; // flushes once it is
            return;
        }
        if (!link.connected)
            return;
        for (const key in pending)
            link.write(JSON.stringify({ op: "set", key: key, value: pending[key] }) + "\n");
        link.flush();
        pending = ({});
    }

    function get(section, key, fallback) {
        const s = store[section];
        if (s && key in s)
            return s[key];
        return fallback;
    }

    function set(section, key, value) {
        const change = {};
        change[section + "." + key] = value;
        store = merged(store, change); // the UI does not wait for the daemon
        pending = Object.assign({}, pending, change);
        if (!sender.running)
            sender.start();
    }
}
