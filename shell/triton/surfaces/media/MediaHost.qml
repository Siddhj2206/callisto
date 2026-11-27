pragma ComponentBehavior: Bound

import QtQuick
import qs.patterns
import qs.services
import qs.surfaces.media
import qs.tokens

// The player popover under the bar's media pill.
Popover {
    id: root

    centred: true
    open: MediaService.popoverOpen
    panelWidth: Metrics.mediaWidth
    panelHeight: card.implicitHeight + Metrics.panelPad * 2
    onDismissed: MediaService.popoverOpen = false
    onBack: MediaService.popoverOpen = false

    // Players do not report their position unasked.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.open && MediaService.playing
        onTriggered: MediaService.current?.positionChanged()
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space)
                MediaService.togglePlaying();
            else if (event.key === Qt.Key_Left)
                MediaService.previous();
            else if (event.key === Qt.Key_Right)
                MediaService.next();
            else
                return;
            event.accepted = true;
        }

        PlayerCard {
            id: card
            x: Metrics.panelPad
            y: Metrics.panelPad
            width: parent.width - Metrics.panelPad * 2
            player: MediaService.current
            others: MediaService.players
            position: MediaService.current?.position ?? 0

            onToggleRequested: player => MediaService.togglePlaying(player)
            onNextRequested: MediaService.next()
            onPreviousRequested: MediaService.previous()
            onSeekRequested: fraction => MediaService.seek(fraction)
            onShuffleRequested: MediaService.toggleShuffle()
            onLoopRequested: MediaService.cycleLoop()
            onChosen: player => MediaService.choose(player)
        }
    }
}
