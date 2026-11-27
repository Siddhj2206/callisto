pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// One app's notifications. Folded, it shows the newest with the edge of the
// next peeking out; open, the newest few and a way to the rest.
Column {
    id: root

    property string app: ""
    property string icon: ""
    property var items: [] // newest first
    property var describe: item => item // item -> NotificationCard entry
    property bool folded: false
    property bool showAll: false
    readonly property int preview: 3

    signal foldToggled
    signal showAllRequested
    signal cleared
    signal activated(var item)
    signal dismissed(var item)
    signal actionTriggered(var item, string id)
    signal replied(var item, string text)

    readonly property var shown: folded ? items.slice(0, 1) : showAll ? items : items.slice(0, preview)
    readonly property Scheme scheme: Theming.of(root)

    spacing: Metrics.cardActions

    Item {
        width: parent.width
        height: Metrics.control

        Avatar {
            id: disc
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.discSm
            source: root.icon
        }
        AppText {
            id: name
            anchors.left: disc.right
            anchors.leftMargin: Metrics.cardGap
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width / 2)
            role: "label"
            textFormat: Text.PlainText
            text: root.app
        }
        AppText {
            anchors.left: name.right
            anchors.leftMargin: Metrics.cardActions
            anchors.verticalCenter: parent.verticalCenter
            role: "bodySmall"
            tone: "onsurfacevariant"
            text: root.items.length
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            IconButton {
                visible: root.items.length > 1
                size: Metrics.control
                glyph: root.folded ? Icons.expandMore : Icons.expandLess
                label: root.folded ? "Expand " + root.app : "Collapse " + root.app
                onClicked: root.foldToggled()
            }
            Button {
                height: Metrics.control
                variant: "text"
                text: "Clear"
                onClicked: root.cleared()
            }
        }
    }

    Repeater {
        model: ScriptModel { values: root.shown }

        NotificationCard {
            required property var modelData

            width: root.width
            floating: false
            entry: root.describe(modelData)
            onClicked: root.activated(modelData)
            onDismissed: root.dismissed(modelData)
            onActionTriggered: id => root.actionTriggered(modelData, id)
            onReplied: text => root.replied(modelData, text)
        }
    }

    Item {
        visible: root.folded && root.items.length > 1
        width: parent.width
        height: Metrics.peekHeight - root.spacing

        Rectangle {
            y: -root.spacing
            x: Metrics.peekInset
            width: parent.width - Metrics.peekInset * 2
            height: Metrics.peekHeight
            color: root.scheme.veil
            opacity: Theme.stateDimmed
            bottomLeftRadius: Metrics.listCardRadius
            bottomRightRadius: Metrics.listCardRadius
        }
    }

    Button {
        visible: !root.folded && root.items.length > root.shown.length
        height: Metrics.control
        variant: "text"
        text: "Show " + (root.items.length - root.shown.length) + " more"
        onClicked: root.showAllRequested()
    }
}
