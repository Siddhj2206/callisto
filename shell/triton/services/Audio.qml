pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Non-visual audio service singleton.
//
// Wraps the Pipewire default sink. All properties degrade to null/false when
// no sink exists (VMs, device transitions), so consumers can hide volume UI
// instead of rendering placeholder garbage.
//
// Interaction contract for the OSD: `volumeInteracted` and `muteInteracted`
// are emitted exactly when the user-facing state changes — both when we write
// it ourselves (volumeUp/Down/toggleMute) and when something external does
// (another client, hardware keys routed through wireplumber). The first read
// of a freshly appeared sink never emits, so the OSD does not pop at shell
// startup or on device transitions.
Singleton {
    id: root

    // Step per volumeUp/volumeDown call, and the overdrive ceiling.
    readonly property real step: 0.05
    readonly property real maxVolume: 1.5

    // Null when there is no default sink. Never write through this without
    // a null check.
    readonly property PwNode sink: Pipewire.defaultAudioSink

    readonly property bool ready: Pipewire.ready
    readonly property bool available: root.sink !== null && root.sink.audio !== null

    // 0..1+, proportional across all channels. Null when unavailable.
    readonly property var volume: root.available ? root.sink.audio.volume : null
    readonly property bool muted: root.available ? root.sink.audio.muted : false

    signal volumeInteracted(real volume)
    signal muteInteracted(bool muted)

    // Pipewire node properties are invalid until the object is bound.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Suppression of first reads: `_primedVolumeFor` records which sink object
    // the current volume value was first observed on. A change is a real
    // interaction only if the sink object is unchanged since its first read.
    property var _primedVolumeFor: null
    property var _primedMuteFor: null

    onVolumeChanged: {
        if (!root.available) return;
        const sinkObj = root.sink;
        if (root._primedVolumeFor === sinkObj) {
            root.volumeInteracted(root.volume);
        } else {
            root._primedVolumeFor = sinkObj;
        }
    }

    onMutedChanged: {
        if (!root.available) return;
        const sinkObj = root.sink;
        if (root._primedMuteFor === sinkObj) {
            root.muteInteracted(root.muted);
        } else {
            root._primedMuteFor = sinkObj;
        }
    }

    function _writeVolume(v) {
        if (!root.available) return;
        root.sink.audio.volume = Math.max(0, Math.min(root.maxVolume, v));
    }

    function volumeUp() {
        if (!root.available) return;
        // Raising the volume from keys unmutes, matching every major DE.
        if (root.muted) root.sink.audio.muted = false;
        root._writeVolume(root.volume + root.step);
        root.volumeInteracted(root.sink.audio.volume);
    }

    function volumeDown() {
        if (!root.available) return;
        if (root.muted) root.sink.audio.muted = false;
        root._writeVolume(root.volume - root.step);
        root.volumeInteracted(root.sink.audio.volume);
    }

    function toggleMute() {
        if (!root.available) return;
        root.sink.audio.muted = !root.muted;
        root.muteInteracted(root.sink.audio.muted);
    }
}
