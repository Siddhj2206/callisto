pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// One player in full, and the others to switch to. A pure view.
Column {
    id: root

    property var player: null // anything shaped like an MprisPlayer
    property var others: [] // every player, shown when there is more than one
    property real position: 0 // seconds

    signal toggleRequested(var player)
    signal nextRequested
    signal previousRequested
    signal seekRequested(real fraction)
    signal shuffleRequested
    signal loopRequested
    signal chosen(var player)

    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.lengthSupported ? player.length : 0

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const rest = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + rest : m + ":" + rest;
    }

    spacing: Metrics.panelGap

    Row {
        width: parent.width
        spacing: Metrics.panelGap

        PlayerArt {
            id: art
            size: Metrics.mediaArtLarge
            source: root.player?.trackArtUrl ?? ""
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - art.width - parent.spacing

            AppText {
                width: parent.width
                role: "headline"
                textFormat: Text.PlainText
                text: root.player?.trackTitle ?? ""
            }
            AppText {
                width: parent.width
                visible: text !== ""
                role: "body"
                textFormat: Text.PlainText
                text: [root.player?.trackArtist, root.player?.trackAlbum].filter(part => part).join(" · ")
            }
            AppText {
                width: parent.width
                role: "bodySmall"
                tone: "onsurfacevariant"
                textFormat: Text.PlainText
                text: root.player?.identity ?? ""
            }
        }
    }

    Column {
        width: parent.width
        visible: root.length > 0

        WavyProgress {
            width: parent.width
            value: root.length > 0 ? root.position / root.length : 0
            seekable: root.player?.canSeek ?? false
            onSeeked: fraction => root.seekRequested(fraction)
        }
        Item {
            width: parent.width
            height: elapsed.height

            AppText {
                id: elapsed
                role: "bodySmall"
                tone: "onsurfacevariant"
                tabular: true
                text: root.clock(root.position)
            }
            AppText {
                anchors.right: parent.right
                role: "bodySmall"
                tone: "onsurfacevariant"
                tabular: true
                text: root.clock(root.length)
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Metrics.panelGap

        IconButton {
            visible: root.player?.shuffleSupported ?? false
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.control
            variant: "veil"
            selected: root.player?.shuffle ?? false
            glyph: Icons.shuffle
            label: "Shuffle"
            onClicked: root.shuffleRequested()
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.control
            variant: "veil"
            visible: root.player?.canGoPrevious ?? false
            glyph: Icons.skipPrevious
            label: "Previous"
            onClicked: root.previousRequested()
        }
        IconButton {
            size: Metrics.playButton
            variant: "filled"
            iconSize: "lg"
            glyph: root.playing ? Icons.pause : Icons.playArrow
            label: root.playing ? "Pause" : "Play"
            onClicked: root.toggleRequested(root.player)
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.control
            variant: "veil"
            visible: root.player?.canGoNext ?? false
            glyph: Icons.skipNext
            label: "Next"
            onClicked: root.nextRequested()
        }
        IconButton {
            visible: root.player?.loopSupported ?? false
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.control
            variant: "veil"
            // MprisLoopState: none, one track, the playlist.
            selected: (root.player?.loopState ?? 0) !== 0
            glyph: Icons.repeat
            label: "Repeat"
            onClicked: root.loopRequested()
        }
    }

    Column {
        width: parent.width
        visible: root.others.length > 1
        spacing: Metrics.listGap

        Repeater {
            model: root.others

            ListRow {
                required property var modelData
                required property int index

                width: parent.width
                first: index === 0
                last: index === root.others.length - 1
                selected: modelData === root.player
                glyph: Icons.musicNote
                title: modelData.trackTitle
                subtitle: [modelData.trackArtist, modelData.identity].filter(part => part).join(" · ")
                onClicked: root.chosen(modelData)
                trailingGlyph: modelData.isPlaying ? Icons.pause : Icons.playArrow
                trailingAction: (modelData.isPlaying ? "Pause " : "Play ") + modelData.trackTitle
                onTrailingClicked: root.toggleRequested(modelData)
            }
        }
    }
}
