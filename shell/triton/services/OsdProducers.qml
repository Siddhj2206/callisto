pragma ComponentBehavior: Bound

import Quickshell
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
    Component.onCompleted: lastBrightness = BrightnessService.level
}
