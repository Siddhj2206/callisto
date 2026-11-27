import QtQuick
import qs.foundations
import qs.tokens

// A card's life in the toast stack: it opens a gap and slides in, times out
// unless hovered or being typed into, then fades and closes the gap.
Item {
    id: root

    required property var entry
    property bool sticky: false
    property int timeout: Motion.toastHold

    signal expired
    signal closed // dismissed by the user; fires after the fade
    signal clicked
    signal actionTriggered(string id)
    signal replied(string text)

    property var leaving: null // the signal to send once gone
    property bool entered: false
    Component.onCompleted: entered = true

    function leave(then) {
        if (!leaving)
            leaving = then;
    }

    implicitHeight: gap.value

    Spring {
        id: gap
        to: root.leaving && presence.opacity === 0 ? 0 : card.implicitHeight + Metrics.cardActions
        token: Motion.spatialDefault
        epsilon: 0.5
        onRunningChanged: {
            if (!running && root.leaving && presence.opacity === 0)
                root.leaving();
        }
    }

    Timer {
        id: timer
        running: !root.sticky && !root.leaving && !card.hovered && !card.busy
        interval: root.timeout
        onTriggered: root.leave(() => root.expired())
    }

    // An app updating its notification starts the clock again.
    readonly property string content: entry.title + "\n" + entry.body + "\n" + entry.progress
    onContentChanged: {
        if (timer.running)
            timer.restart();
    }

    Presence {
        id: presence
        width: parent.width
        height: card.implicitHeight
        show: root.entered && !root.leaving
        fromX: Metrics.toastSlide
        // Reduced motion snaps the spring before the fade ends; close up then.
        onOpacityChanged: {
            if (root.leaving && opacity === 0 && !gap.running)
                root.leaving();
        }

        NotificationCard {
            id: card
            width: parent.width
            entry: root.entry
            onClicked: root.leave(() => root.clicked())
            onDismissed: root.leave(() => root.closed())
            onActionTriggered: id => root.actionTriggered(id)
            onReplied: text => root.replied(text)
        }
    }
}
