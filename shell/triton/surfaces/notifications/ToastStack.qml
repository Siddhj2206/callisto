pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.tokens

// At most four toasts, newest on top; the rest wait as a count.
Column {
    id: root

    property var items: [] // newest first
    property var describe: item => item // item -> NotificationCard entry
    property var isSticky: item => item.critical === true
    readonly property int limit: 4
    property int timeout: Motion.toastHold

    signal expired(var item)
    signal closed(var item)
    signal activated(var item)
    signal actionTriggered(var item, string id)
    signal replied(var item, string text)

    Repeater {
        model: ScriptModel { values: root.items.slice(0, root.limit) }

        Toast {
            required property var modelData

            width: root.width
            entry: root.describe(modelData)
            sticky: root.isSticky(modelData)
            timeout: root.timeout
            onExpired: root.expired(modelData)
            onClosed: root.closed(modelData)
            onClicked: root.activated(modelData)
            onActionTriggered: id => root.actionTriggered(modelData, id)
            onReplied: text => root.replied(modelData, text)
        }
    }

    Item {
        visible: root.items.length > root.limit
        width: parent.width
        height: Metrics.control

        Material {
            anchors.right: parent.right
            width: more.implicitWidth + Metrics.cardPad * 2
            height: parent.height
            radius: height / 2

            Row {
                id: more
                anchors.centerIn: parent
                spacing: Metrics.cardActions

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Icons.stacks
                }
                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "label"
                    text: (root.items.length - root.limit) + " more"
                }
            }
        }
    }
}
