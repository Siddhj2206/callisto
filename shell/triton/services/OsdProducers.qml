pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Shows the matching OSD when volume, microphone mute or backlight change,
// whatever changed them. Start-up readings show nothing, and neither do
// changes made with the quick settings sliders, which are their own feedback.
Scope {
    id: root

    property bool settled: false
    Timer {
        id: settle
        interval: 1000
        running: true
        onTriggered: root.settled = true
    }

    readonly property bool quiet: !settled || QuickSettingsState.open

    function showSink() {
        if (!quiet && AudioService.available)
            OsdState.show(AudioService.muted ? "muted" : "volume", AudioService.volume);
    }

    // A new default output is not a volume change.
    Connections {
        target: AudioService
        function onSinkChanged() {
            root.settled = false;
            settle.restart();
        }
        function onVolumeChanged() { root.showSink(); }
        function onMutedChanged() { root.showSink(); }
    }

    Connections {
        target: AudioService.source?.audio ?? null
        function onMutedChanged() {
            if (root.quiet)
                return;
            if (AudioService.source.audio.muted)
                OsdState.show("micOff");
            else if (OsdState.kind === "micOff")
                OsdState.dismiss();
        }
    }

    // Each level warns once per discharge. Not held back by quick settings, and
    // the first reading counts: logging in on an empty battery should say so.
    readonly property var levels: [5, 10, 20]
    property int warned: 101 // the lowest level already warned about
    readonly property bool draining: SessionStatus.hasBattery && UPower.onBattery
    readonly property int percent: SessionStatus.batteryPercent

    function timeLeft(seconds) {
        if (seconds <= 0)
            return "";
        const minutes = Math.round(seconds / 60);
        if (minutes < 60)
            return "About " + minutes + " minutes left";
        const hours = Math.round(minutes / 60);
        return "About " + hours + (hours === 1 ? " hour left" : " hours left");
    }

    function checkBattery() {
        if (!draining) {
            warned = 101;
            if (OsdState.kind === "battery")
                OsdState.dismiss();
            return;
        }
        const level = levels.find(l => percent <= l && l < warned);
        if (level === undefined)
            return;
        warned = level;
        OsdState.warn(percent / 100, timeLeft(SessionStatus.battery.timeToEmpty), level === levels[0]);
    }

    onDrainingChanged: checkBattery()
    onPercentChanged: checkBattery()

    Connections {
        target: MediaService
        function onAnnounced() {
            if (MediaService.current)
                OsdState.showTrack(MediaService.current);
        }
    }

    property real lastBrightness: -1
    Connections {
        target: BrightnessService
        function onLevelChanged() {
            const level = BrightnessService.level;
            if (!root.quiet && root.lastBrightness >= 0)
                OsdState.show("brightness", level);
            root.lastBrightness = level;
        }
    }
    Component.onCompleted: {
        lastBrightness = BrightnessService.level;
        checkBattery();
    }
}
