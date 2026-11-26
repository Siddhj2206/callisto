pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// A notification card (Notifications board `.nc`): Glass, padding 14/16/14/14,
// radius 24 24 24 10, 14px gap between the leading visual and the text column.
//
// Leading visual: either a 48px wave avatar (message contacts, tertiary-
// container fill with Jost initials) or a 48px circular icon disc. Text:
// header name 600 16 + trailing time 12px onv, body 14px onv.
//
// Actions are a model-driven row below the body: inline reply (message),
// progress bar (progress), or small buttons (.b variants). Critical cards
// re-tint everything to the error-container palette and never expire — that
// behavior lives in the controller, not here.

Item {
    id: root

    enum Kind { Standard, Message, Progress, Critical, Call, Screenshot }

    property int kind: NotificationCard.Kind.Standard

    // Leading visual.
    property string iconGlyph: ""
    property bool fillIconGlyph: true
    property string initials: "" // wave avatar mode when non-empty
    property color discColor: Theme.secondaryContainer
    property color discContentColor: Theme.onsecondarycontainer

    // Text.
    property string title: ""
    property string timeText: ""
    property string body: ""

    // Message: inline reply.
    property bool hasReply: false

    // Actions: [{text, style: "pf"|"pt"|"pe"|"pg", small?}] — board variants.
    property var actions: []

    // Progress.
    property real progress: -1 // 0..1, -1 hides
    property string progressText: ""

    signal actionTriggered(int idx)
    signal replySent(string text)
    signal clicked

    implicitWidth: 400
    implicitHeight: cardCol.implicitHeight + 28

    // Click-to-dismiss area is FIRST — behind all interactive content.
    // (It was last originally, which put it on top of the reply field and
    // action buttons, eating every click: the entire action system was dead.)
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.clicked()
    }

    // Asymmetric card body: 24px everywhere except bottom-left at 10px.
    RoundedRect {
        anchors.fill: parent
        radii: root.kind === NotificationCard.Kind.Critical ? [24, 24, 24, 24] : [24, 24, 24, 10]
        color: root.kind === NotificationCard.Kind.Critical ? "#C793000A" // error glass rgb(147 0 10 / .78)
             : Theme.glassBg
    }

    readonly property color nameColor: root.kind === NotificationCard.Kind.Critical ? "#FFDAD6" : Theme.onsurface
    readonly property color bodyColor: root.kind === NotificationCard.Kind.Critical ? "#FFDAD6" : Theme.onsurfacevariant
    readonly property color timeColor: root.kind === NotificationCard.Kind.Critical ? "#FFDAD6" : Theme.onsurfacevariant

    Row {
        id: cardRow
        x: 14
        y: 14
        width: parent.width - 30 // 14 left + 16 right
        spacing: 14

        // Leading visual: wave avatar or icon disc, 48px.
        Item {
            width: 48
            height: 48

            WaveShape {
                visible: root.initials !== ""
                anchors.fill: parent
                size: 48
                color: Theme.tertiaryContainer
            }

            TritonText {
                visible: root.initials !== ""
                anchors.centerIn: parent
                text: root.initials
                family: TritonText.Family.Display
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 18
                color: Theme.ontertiarycontainer
            }

            Rectangle {
                visible: root.initials === ""
                anchors.fill: parent
                radius: 24
                color: root.kind === NotificationCard.Kind.Critical ? "#FFDAD6" : root.discColor

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: root.iconGlyph
                    fill: root.fillIconGlyph
                    size: 24
                    color: root.kind === NotificationCard.Kind.Critical ? "#410002" : root.discContentColor
                }
            }
        }

        Column {
            id: cardCol
            width: parent.width - 48 - 14
            spacing: 0

            // Header: name baseline-aligned with trailing time.
            Item {
                width: parent.width
                height: nameText.implicitHeight

                TritonText {
                    id: nameText
                    text: root.title
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 16
                    color: root.nameColor
                }
                TritonText {
                    anchors.right: parent.right
                    anchors.baseline: nameText.baseline
                    text: root.timeText
                    font.pixelSize: 12
                    color: root.timeColor
                }
            }

            TritonText {
                text: root.body
                font.pixelSize: 14
                color: root.bodyColor
                width: parent.width
                wrapMode: Text.Wrap
                topPadding: 2
            }

            // Inline reply (message): pill field + primary send circle.
            Row {
                visible: root.hasReply
                width: parent.width
                spacing: 8
                topPadding: 12

                Rectangle {
                    width: parent.width - 44
                    height: 36
                    radius: 18
                    color: Theme.veilMid

                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        color: Theme.onsurface
                        clip: true

                        TritonText {
                            visible: replyInput.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Reply"
                            font.pixelSize: 13
                            color: Theme.onsurfacevariant
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.primary

                    TritonIcon {
                        anchors.centerIn: parent
                        glyph: Icons.send
                        fill: true
                        size: 18
                        color: Theme.onprimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.replySent(replyInput.text);
                            replyInput.text = "";
                        }
                    }
                }
            }

            // Progress: track + % (the wavy progress primitive replaces the
            // track when it exists — geometry matches either way).
            Row {
                visible: root.progress >= 0
                width: parent.width
                spacing: 10
                topPadding: 10

                Item {
                    width: parent.width - 130
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "#2EFFFFFF"
                    }
                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 8
                        color: Theme.primary
                    }
                }

                TritonText {
                    text: root.progressText
                    font.pixelSize: 12
                    color: root.bodyColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Action buttons row.
            Row {
                visible: root.actions.length > 0
                spacing: 8
                topPadding: root.progress >= 0 || root.hasReply ? 0 : 12

                Repeater {
                    model: root.actions

                    Rectangle {
                        required property var modelData
                        required property int index
                        height: modelData.small ? 30 : 36
                        width: Math.max(36, actionLabel.implicitWidth + (modelData.small ? 24 : 32))
                        radius: height / 2
                        color: modelData.style === "pf" ? (root.kind === NotificationCard.Kind.Critical ? "#FFDAD6" : Theme.primary)
                             : modelData.style === "pe" ? Theme.errorContainer
                             : modelData.style === "pg" ? "#8CD6A0"
                             : "#24FFFFFF" // pt: white .14

                        TritonText {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text || ""
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 13
                            color: parent.modelData.style === "pf" ? (root.kind === NotificationCard.Kind.Critical ? "#410002" : Theme.onprimary)
                                 : parent.modelData.style === "pe" ? Theme.onerrorcontainer
                                 : parent.modelData.style === "pg" ? "#00391B"
                                 : Theme.onsurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered(index)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
