pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// The screen recording in progress. It runs as its own systemd unit, so this
// only starts it, asks after it and stops it, and finds it again after the
// shell restarts.
Singleton {
    id: root

    property bool recording: false
    property bool stopping: false
    property int seconds: 0
    property string path: ""
    readonly property string elapsed: Math.floor(seconds / 60).toString().padStart(2, "0")
        + ":" + (seconds % 60).toString().padStart(2, "0")

    signal finished(string path, int seconds)
    signal failed

    function start(args) {
        if (recording || starter.running)
            return;
        starter.command = ["callisto-shot", "record"].concat(args);
        starter.running = true;
    }

    function stop() {
        if (!recording || stopping)
            return;
        stopping = true;
        Quickshell.execDetached(["callisto-shot", "stop"]);
    }

    Process {
        id: starter
        stdout: StdioCollector {
            id: started
        }
        onExited: code => {
            if (code !== 0) {
                root.failed();
                return;
            }
            root.path = started.text.trim();
            root.seconds = 0;
            root.recording = true;
        }
    }

    Process {
        id: asker
        running: true // once at start, for a recording that was already going
        command: ["callisto-shot", "status"]
        stdout: StdioCollector {
            id: told
        }
        onExited: code => {
            if (code === 0) {
                const [path, seconds] = told.text.trim().split("\t");
                root.path = path;
                root.seconds = Number(seconds);
                root.recording = true;
            } else if (root.recording) {
                // Stopped by us, or it ended by itself. Under a second of
                // recording means it never got going.
                const asked = root.stopping;
                root.recording = false;
                root.stopping = false;
                if (asked || root.seconds > 1)
                    root.finished(root.path, root.seconds);
                else
                    root.failed();
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: asker.running = true
    }
}
