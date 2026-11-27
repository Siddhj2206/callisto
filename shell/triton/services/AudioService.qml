pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default output and microphone, and the list of outputs to choose from.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var audio: sink?.audio ?? null
    readonly property bool available: audio !== null
    readonly property real volume: available ? audio.volume : 0
    readonly property bool muted: available ? audio.muted : false
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio !== null)

    PwObjectTracker { objects: [root.sink, root.source, ...root.outputs].filter(node => node !== null) }

    function name(node) {
        return node ? (node.description || node.nickname || node.name) : "";
    }

    function setVolume(value) {
        if (!available)
            return;
        audio.volume = Math.max(0, Math.min(1, value));
        if (value > 0)
            audio.muted = false;
    }

    function stepVolume(steps) {
        setVolume(volume + steps * 0.05);
    }

    function toggleMute() {
        if (available)
            audio.muted = !audio.muted;
    }

    function setOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
}
