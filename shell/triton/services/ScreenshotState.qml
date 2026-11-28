pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.services
import qs.tokens

// Taking a screenshot. The screens are frozen before anything is drawn over
// them, so menus and hover states are caught and the tool itself never is.
Singleton {
    id: root

    property bool open: false // a capture is under way
    property bool ready: false // frozen, the tool is on screen
    property string mode: "region" // "region" | "window" | "screen", remembered
    property int delay: 0 // seconds
    property bool pointer: false
    property bool video: false // record instead of taking a picture
    property string audio: "" // "" | "mic" | "system", one source at a time
    readonly property int videoCountdown: 3
    property int countdown: 0
    property var result: null // { path, width, height, saved }

    readonly property string frozenDir: Quickshell.env("XDG_RUNTIME_DIR") + "/callisto/frozen"
    property int generation: 0 // changes the image URLs on every freeze

    function frozen(screenName) {
        return "file://" + frozenDir + "/" + screenName + ".ppm?" + generation;
    }

    // Print also ends a recording.
    function toggle() {
        if (RecordState.recording)
            RecordState.stop();
        else if (open)
            cancel();
        else
            start("freeze");
    }

    // The focused screen, at once.
    function screenNow() {
        if (!open)
            start("screen");
    }

    // The focused window, at once.
    function windowNow() {
        if (open || !Hyprland.activeToplevel)
            return;
        Hyprland.refreshToplevels(); // where it is now
        start("window");
    }

    property string pending: "" // what to do once the screen has settled
    property var request: null // the capture waiting for that

    function start(what) {
        result = null;
        open = true;
        ready = false;
        pending = what;
        settle.restart();
    }

    function cancel() {
        settle.stop();
        ticker.stop();
        countdown = 0;
        ready = false;
        open = false;
        forget();
    }

    // The frozen screens hold whatever was on them.
    function forget() {
        Quickshell.execDetached(["rm", "-rf", "--", frozenDir]);
    }

    function cycleDelay() {
        delay = delay === 0 ? 3 : delay === 3 ? 5 : delay === 5 ? 10 : 0;
    }

    // rect is in the screen's logical coordinates.
    function capture(screen, rect, copyOnly) {
        const geometry = Math.round(screen.x + rect.x) + "," + Math.round(screen.y + rect.y)
            + " " + Math.round(rect.width) + "x" + Math.round(rect.height);
        if (video) {
            const area = mode === "screen" ? ["-o", screen.name] : ["-g", geometry];
            countDown({ record: (audio !== "" ? ["--audio", audio] : []).concat(area) },
                Math.max(delay, videoCountdown));
            return;
        }
        const flags = copyOnly ? ["--copy-only"] : [];
        if (delay === 0) {
            const scale = screen.scale;
            run(["callisto-shot", "crop"].concat(flags, [frozenDir + "/" + screen.name + ".ppm",
                Math.round(rect.x * scale), Math.round(rect.y * scale),
                Math.round(rect.width * scale), Math.round(rect.height * scale)].map(String)), copyOnly);
            return;
        }
        // A delayed capture is of the screen as it is then, not as frozen.
        countDown({ command: ["callisto-shot", "grab"].concat(flags, pointer ? ["--pointer"] : [], ["-g", geometry]),
            copyOnly: copyOnly }, delay);
    }

    function countDown(what, seconds) {
        request = what;
        ready = false;
        countdown = seconds;
        ticker.restart();
    }

    property bool copyingOnly: false

    function run(command, copyOnly) {
        ready = false;
        copyingOnly = copyOnly;
        shot.command = command;
        shot.running = true;
    }

    Timer {
        id: ticker
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0) {
                stop();
                root.pending = "request";
                settle.restart();
            }
        }
    }

    // Time for toasts, the bar and the countdown to leave the screen.
    Timer {
        id: settle
        interval: Motion.captureSettle
        onTriggered: {
            if (root.pending === "freeze") {
                root.generation += 1;
                freezer.command = ["callisto-shot", "freeze"].concat(root.pointer ? ["--pointer"] : [],
                    [root.frozenDir], Quickshell.screens.map(s => s.name));
                freezer.running = true;
            } else if (root.pending === "window") {
                const window = Hyprland.activeToplevel?.lastIpcObject;
                if (window?.at)
                    root.run(["callisto-shot", "grab", "-g", window.at[0] + "," + window.at[1] + " " + window.size[0] + "x" + window.size[1]], false);
                else
                    root.failed();
            } else if (root.pending === "screen") {
                root.run(["callisto-shot", "grab", "-o", Hyprland.focusedMonitor.name], false);
            } else if (root.request.record) {
                root.open = false;
                root.forget();
                RecordState.start(root.request.record);
            } else {
                root.run(root.request.command, root.request.copyOnly);
            }
        }
    }

    Connections {
        target: RecordState
        function onFinished(path, seconds) {
            root.result = { path: path, video: true, seconds: seconds, saved: true };
        }
        function onFailed() {
            Quickshell.execDetached(["notify-send", "-u", "critical", "Recording failed",
                "The screen could not be recorded."]);
        }
    }

    function failed() {
        cancel();
        Quickshell.execDetached(["notify-send", "-u", "critical", "Screenshot failed",
            "The screen could not be captured."]);
    }

    Process {
        id: freezer
        onExited: code => {
            if (code !== 0)
                root.failed();
            else if (root.open)
                root.ready = true;
        }
    }

    Process {
        id: shot
        stdout: StdioCollector {
            id: printed
        }
        onExited: code => {
            if (code !== 0) {
                root.failed();
                return;
            }
            const [path, width, height] = printed.text.trim().split("\t");
            root.open = false;
            root.forget();
            root.result = { path: path, width: Number(width), height: Number(height), saved: !root.copyingOnly };
        }
    }

    // ---- what to do with it ----------------------------------------------------
    function view() {
        Quickshell.execDetached(["uwsm-app", "--", "xdg-open", result.path]);
        result = null;
    }

    function showFolder() {
        Quickshell.execDetached(["uwsm-app", "--", "xdg-open",
            result.path.slice(0, result.path.lastIndexOf("/"))]);
        result = null;
    }

    function discard() {
        Quickshell.execDetached(["callisto-shot", "delete", result.path]);
        result = null;
    }
}
