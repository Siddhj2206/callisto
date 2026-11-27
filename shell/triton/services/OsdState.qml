pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.tokens

// One on-screen display at a time. A new one replaces the old in place and
// restarts the hold. The content stays set while it fades out.
Singleton {
    id: root

    property bool open: false
    property string kind: "volume" // "volume" | "muted" | "brightness" | "micOff" | "battery" | "track"
    property real value: 0
    property string detail: "" // second line of the battery warning
    property bool lasting: false // stays until dismissed

    function show(newKind, newValue) {
        kind = newKind;
        if (newValue !== undefined)
            value = newValue;
        open = true;
        // A muted microphone stays up until it is unmuted.
        lasting = newKind === "micOff";
        restart();
    }

    // The battery warning stays longer, and an empty battery's until power is
    // back.
    function warn(level, text, stays) {
        kind = "battery";
        value = level;
        detail = text;
        lasting = stays;
        open = true;
        restart();
    }

    // What the media keys did.
    property var track: null // { title, artist, art, playing }
    function showTrack(player) {
        track = { title: player.trackTitle, artist: player.trackArtist, art: player.trackArtUrl, playing: player.isPlaying };
        kind = "track";
        lasting = false;
        open = true;
        restart();
    }

    function restart() {
        if (lasting) {
            hold.stop();
            return;
        }
        hold.interval = kind === "battery" ? Motion.osdAction : Motion.osdHold;
        hold.restart();
    }

    function dismiss() {
        hold.stop();
        open = false;
    }

    Timer {
        id: hold
        onTriggered: root.open = false
    }
}
