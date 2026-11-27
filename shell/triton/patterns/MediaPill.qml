import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// What is playing, in a row: art, title and artist, and the transport. Previous
// and next come out when the pointer is over it. Click the text for more.
Item {
    id: root

    property var player: null // anything shaped like an MprisPlayer
    property bool wide: false // previous and next always out

    signal toggleRequested
    signal nextRequested
    signal previousRequested
    signal opened

    readonly property bool expanded: wide || hover.hovered
    readonly property bool playing: player?.isPlaying ?? false

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.barSlot

    HoverHandler { id: hover }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.barGap

        Pressable {
            anchors.verticalCenter: parent.verticalCenter
            width: info.implicitWidth + Metrics.statusPad
            height: Metrics.barSlot
            label: "Now playing: " + (root.player?.trackTitle ?? "")
            onClicked: root.opened()

            Row {
                id: info
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.titleGap

                PlayerArt {
                    anchors.verticalCenter: parent.verticalCenter
                    source: root.player?.trackArtUrl ?? ""
                    opacity: root.playing ? 1 : Theme.stateDimmed
                }
                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Metrics.mediaTitleMax)
                    role: "label"
                    textFormat: Text.PlainText
                    text: root.player?.trackTitle ?? ""
                }
                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    width: Math.min(implicitWidth, Metrics.mediaTitleMax / 2)
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    textFormat: Text.PlainText
                    text: root.player?.trackArtist ?? ""
                }
            }
        }
        IconButton {
            visible: root.expanded && (root.player?.canGoPrevious ?? false)
            anchors.verticalCenter: parent.verticalCenter
            variant: "veil"
            glyph: Icons.skipPrevious
            label: "Previous"
            onClicked: root.previousRequested()
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            variant: "filled"
            glyph: root.playing ? Icons.pause : Icons.playArrow
            label: root.playing ? "Pause" : "Play"
            onClicked: root.toggleRequested()
        }
        IconButton {
            visible: root.expanded && (root.player?.canGoNext ?? false)
            anchors.verticalCenter: parent.verticalCenter
            variant: "veil"
            glyph: Icons.skipNext
            label: "Next"
            onClicked: root.nextRequested()
        }
    }
}
