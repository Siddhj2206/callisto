pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// One notification. A pure view of an `entry`:
// { title, body, time, icon, picture, critical, progress, actions: [{ id, text }],
//   replyable, replyHint }
Item {
    id: root

    required property var entry
    property bool floating: true // a toast, as opposed to a row in the center
    readonly property bool hovered: hover.hovered
    // A half-typed reply must not time out from under the user.
    readonly property bool busy: reply.item?.typing ?? false

    signal clicked
    signal dismissed
    signal actionTriggered(string id)
    signal replied(string text)

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: entry.critical ? "onerrorcontainer" : "onsurface"
    readonly property string quietTone: entry.critical ? "onerrorcontainer" : "onsurfacevariant"
    readonly property real corner: floating ? Metrics.cardRadius : Metrics.listCardRadius
    readonly property real tail: floating ? Metrics.cardTail : Metrics.listCardTail

    implicitHeight: content.implicitHeight + Metrics.cardPad * 2

    Rectangle {
        anchors.fill: parent
        color: root.entry.critical ? root.scheme.errorContainer : root.floating ? root.scheme.glass : root.scheme.veil
        topLeftRadius: root.corner
        topRightRadius: root.corner
        bottomRightRadius: root.corner
        bottomLeftRadius: root.tail
    }

    HoverHandler {
        id: hover
    }

    Pressable {
        anchors.fill: parent
        radius: root.corner
        ink: root.scheme[root.tone]
        label: root.entry.title
        onClicked: root.clicked()
    }

    Avatar {
        id: avatar
        visible: root.floating
        x: Metrics.cardPad
        y: Metrics.cardPad
        source: root.entry.picture || root.entry.icon
        picture: root.entry.picture !== ""
        glyph: root.entry.critical ? Icons.error : Icons.notifications
    }

    Column {
        id: content
        anchors.left: root.floating ? avatar.right : parent.left
        anchors.leftMargin: root.floating ? Metrics.cardGap : Metrics.cardPad
        anchors.right: parent.right
        anchors.rightMargin: Metrics.cardPad
        y: Metrics.cardPad

        Item {
            width: parent.width
            height: title.implicitHeight

            AppText {
                id: title
                anchors.left: parent.left
                anchors.right: end.left
                anchors.rightMargin: Metrics.cardGap
                role: "label"
                tone: root.tone
                textFormat: Text.PlainText
                text: root.entry.title
            }
            Item {
                id: end
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(time.implicitWidth, close.width)
                height: parent.height

                AppText {
                    id: time
                    visible: !root.hovered
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    role: "bodySmall"
                    tone: root.quietTone
                    text: root.entry.time
                }
                IconButton {
                    id: close
                    visible: root.hovered || activeFocus
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    size: Metrics.discSm
                    iconSize: "sm"
                    variant: "veil"
                    glyph: Icons.close
                    label: "Dismiss"
                    onClicked: root.dismissed()
                }
            }
        }

        AppText {
            width: parent.width
            visible: text !== ""
            role: "bodySmall"
            tone: root.quietTone
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.floating ? 2 : 3
            text: root.entry.body
        }

        Item {
            visible: root.entry.progress >= 0
            width: parent.width
            height: Metrics.control

            Progress {
                anchors.left: parent.left
                anchors.right: percent.left
                anchors.rightMargin: Metrics.cardGap
                anchors.verticalCenter: parent.verticalCenter
                value: root.entry.progress / 100
            }
            AppText {
                id: percent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                role: "bodySmall"
                tone: root.quietTone
                tabular: true
                text: root.entry.progress + "%"
            }
        }

        Loader {
            id: reply
            width: parent.width
            active: root.entry.replyable
            visible: active
            sourceComponent: Item {
                readonly property bool typing: field.activeFocus && field.text !== ""

                function send() {
                    if (field.text !== "")
                        root.replied(field.text);
                }

                implicitHeight: Metrics.control + Metrics.cardActions

                TextField {
                    id: field
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: sendButton.left
                    anchors.rightMargin: Metrics.cardActions
                    height: Metrics.control
                    placeholder: root.entry.replyHint || "Reply"
                    onAccepted: parent.send()
                }
                IconButton {
                    id: sendButton
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    size: Metrics.control
                    variant: "filled"
                    glyph: Icons.send
                    label: "Send"
                    onClicked: parent.send()
                }
            }
        }

        Item {
            visible: root.entry.actions.length > 0
            width: parent.width
            height: actions.implicitHeight + Metrics.cardActions

            Flow {
                id: actions
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: Metrics.cardActions

                Repeater {
                    model: root.entry.actions

                    Button {
                        required property var modelData
                        required property int index

                        height: Metrics.control
                        variant: index === 0 ? "filled" : "veil"
                        text: modelData.text
                        onClicked: root.actionTriggered(modelData.id)
                    }
                }
            }
        }
    }
}
