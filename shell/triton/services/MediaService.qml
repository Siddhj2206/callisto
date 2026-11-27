pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQml
import QtQuick
import qs.tokens

// What is playing, from any MPRIS player. The most recently played one owns the
// bar's pill until another starts or the list picks a different one.
Singleton {
    id: root

    // Players with something to show.
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle !== "")
    property var chosen: null
    readonly property var current: players.includes(chosen) ? chosen
        : players.find(p => p.isPlaying) ?? players[0] ?? null

    // A paused player leaves the bar after a while, and returns when it plays.
    property bool faded: false
    readonly property bool present: current !== null && current.playbackState !== MprisPlaybackState.Stopped && !faded
    readonly property bool playing: current?.isPlaying ?? false

    property bool popoverOpen: false

    onPlayingChanged: {
        if (playing) {
            faded = false;
            pause.stop();
        } else {
            pause.restart();
        }
    }
    onPresentChanged: {
        if (!present)
            popoverOpen = false;
    }

    Timer {
        id: pause
        interval: Motion.mediaPauseFade
        running: !root.playing
        onTriggered: root.faded = true
    }

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property var modelData
            target: modelData

            function onIsPlayingChanged() {
                if (modelData.isPlaying) {
                    root.chosen = modelData;
                    root.faded = false;
                }
            }
        }
    }

    function choose(player) {
        chosen = player;
        faded = false;
        // Picking a paused player gives it the same time on the bar again.
        if (!playing)
            pause.restart();
    }

    function togglePlaying(player = current) {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(player = current) {
        if (player?.canGoNext)
            player.next();
    }

    function previous(player = current) {
        if (player?.canGoPrevious)
            player.previous();
    }

    function seek(fraction, player = current) {
        if (player?.canSeek && player.lengthSupported)
            player.position = fraction * player.length;
    }

    function toggleShuffle(player = current) {
        if (player?.shuffleSupported && player.canControl)
            player.shuffle = !player.shuffle;
    }

    // Off, the whole list, one track.
    function cycleLoop(player = current) {
        if (!player?.loopSupported || !player.canControl)
            return;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    // ---- media keys: say what is playing, since the bar stays hidden --------
    signal announced

    function key(action) {
        if (!current)
            return;
        if (action === "next")
            next();
        else if (action === "previous")
            previous();
        else
            togglePlaying();
        // The player takes a moment to report the new state.
        announce.restart();
    }

    Timer {
        id: announce
        interval: Motion.mediaAnnounce / 8
        onTriggered: root.announced()
    }

    // The track can change after the first announcement.
    Connections {
        target: root.current
        function onPostTrackChanged() {
            if (follow.running)
                root.announced();
        }
    }
    Timer {
        id: follow
        interval: Motion.mediaAnnounce
    }
    onAnnounced: {
        if (announce.running === false)
            follow.restart();
    }
}
