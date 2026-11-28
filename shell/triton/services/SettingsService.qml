pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.tokens

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
    // Other requests it has not taken yet.
    property var requests: []

    // A display mode on trial: { output, mode, left (seconds) }, or null. The
    // daemon puts the old one back by itself; this only counts along.
    property var trial: null

    Timer {
        interval: 1000
        repeat: true
        running: root.trial !== null
        onTriggered: root.trial = root.trial.left > 1
            ? Object.assign({}, root.trial, { left: root.trial.left - 1 }) : null
    }

    function send(request) {
        requests = [...requests, request];
        flush();
    }

    function tryMode(output, mode) {
        trial = { output: output, mode: mode, left: Math.round(Motion.modeTrial / 1000) };
        send({ op: "trial", output: output, mode: mode });
    }

    function keepMode() {
        const modes = Object.assign({}, get("display", "modes", {}));
        modes[trial.output] = trial.mode;
        store = merged(store, { "display.modes": modes });
        trial = null;
        send({ op: "keep" });
    }

    function revertMode() {
        trial = null;
        send({ op: "revert" });
    }

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
        if (Object.keys(pending).length > 0 || requests.length > 0)
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
        if (Object.keys(pending).length === 0 && requests.length === 0)
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
        for (const request of requests)
            link.write(JSON.stringify(request) + "\n");
        link.flush();
        pending = ({});
        requests = [];
    }

    function get(section, key, fallback) {
        const s = store[section];
        if (s && key in s)
            return s[key];
        return fallback;
    }

    // Settings read in more than one place, so that their fallbacks agree
    // (configs/callisto/default-settings.json has the shipped values).
    readonly property string defaultWallpaper: "/usr/share/backgrounds/callisto/wallpaper.jpg"
    readonly property string wallpaper: get("appearance", "wallpaper", "") || defaultWallpaper
    readonly property bool wallpaperOnLock: get("appearance", "wallpaperOnLock", true)
    readonly property string appearanceMode: get("appearance", "mode", "dark")
    readonly property string accent: get("appearance", "accent", "planet")
    readonly property string material: get("appearance", "material", "mica")
    readonly property string barMode: get("shell", "barMode", "auto") // "auto" | "edge" | "hidden" | "pinned"
    readonly property int revealDelay: get("shell", "revealDelay", Motion.barRevealDwell)
    readonly property bool revealOnUrgent: get("shell", "revealOnUrgent", true)
    readonly property bool showWindowTitle: get("shell", "showWindowTitle", true)
    readonly property bool batteryWavyRing: get("shell", "batteryWavyRing", false)
    readonly property bool clock24h: get("shell", "clockFormat", "24h") === "24h"
    readonly property bool reduceMotion: get("shell", "reduceMotion", false)
    readonly property bool dnd: get("notifications", "dnd", false)
    readonly property bool lockscreenNotifications: get("notifications", "lockscreenNotifications", true)
    readonly property bool nightLight: get("display", "nightLight", false)

    function set(section, key, value) {
        const change = {};
        change[section + "." + key] = value;
        store = merged(store, change); // the UI does not wait for the daemon
        pending = Object.assign({}, pending, change);
        if (!sender.running)
            sender.start();
    }
}
