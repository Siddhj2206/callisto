pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Watches volume, microphone mute and backlight and shows the matching OSD,
// whatever changed them. The first reading of each is skipped so that start-up
// shows nothing.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker { objects: [root.sink, root.source].filter(node => node !== null) }

    // A node's values are not valid until it is bound; ignore changes until
    // shortly after it appears.
    property bool settled: false
    Timer {
        id: settle
        interval: 1000
        running: true
        onTriggered: root.settled = true
    }
    onSinkChanged: {
        settled = false;
        settle.restart();
    }

    function showSink() {
        const audio = root.sink?.audio;
        if (root.settled && audio)
            OsdState.show(audio.muted ? "muted" : "volume", audio.volume);
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showSink(); }
        function onMutedChanged() { root.showSink(); }
    }

    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            if (!root.settled)
                return;
            if (root.source.audio.muted)
                OsdState.show("micOff");
            else if (OsdState.kind === "micOff")
                OsdState.dismiss();
        }
    }

    // ---- Backlight: sysfs is the truth, whatever wrote it ----
    property string backlight: ""
    property int backlightMax: 0
    property real lastBrightness: -1

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => root.backlight = data.trim()
        }
    }

    FileView {
        path: root.backlight !== "" ? "/sys/class/backlight/" + root.backlight + "/max_brightness" : ""
        onLoaded: root.backlightMax = parseInt(text()) || 0
    }

    FileView {
        path: root.backlight !== "" ? "/sys/class/backlight/" + root.backlight + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.backlightMax <= 0)
                return;
            const level = (parseInt(text()) || 0) / root.backlightMax;
            if (root.lastBrightness >= 0 && Math.abs(level - root.lastBrightness) > 0.005)
                OsdState.show("brightness", level);
            root.lastBrightness = level;
        }
    }
}
