pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications
import "../services"
import ".."

// A single notification toast card, per the Notifications board (.nc).
//
// Glass surface, radius 24 with the bottom-right corner squared to 10px,
// padding 14/16/14/14, 48px circular icon (notification image, app icon, or a
// Triton Symbols glyph in a secondary-container circle), summary 16px/600,
// relative time 12px, body 14px on-surface-variant. Critical notifications
// trade glass for the error container at 78% and never time out.
//
// Leaf rule: receives everything as properties. The expiry timer lives here
// because the board binds timeout behavior to hover ("hover pauses the
// timer"); membership in the queue is owned by the Notifications service.
//
// Type sizes are the board's exact pixel values — the generated Theme does
// not yet carry type-scale tokens.
Item {
    id: root

    required property NotificationItem item
    // SystemClock-driven "now" handed down so time labels update without
    // per-card timers or `new Date()` in bindings.
    property date now: new Date()

    implicitHeight: content.implicitHeight
    implicitWidth: 400

    readonly property bool critical: item ? item.critical : false
    readonly property color fill: critical ? Qt.alpha(Theme.errorContainer, 0.78) : Theme.glassBg
    readonly property color contentColor: critical ? Theme.onerrorcontainer : Theme.onsurface
    readonly property color subColor: critical ? Theme.onerrorcontainer : Theme.onsurfacevariant

    // Expiry: criticals never time out; others use the client timeout or 6s.
    // Hover pauses; leaving hover restarts the full duration.
    Timer {
        id: expireTimer

        interval: root.item ? Math.max(500, root.item.timeoutMs) : 6000
        running: root.item !== null && root.item.popup && root.item.timeoutMs > 0 && !hoverHandler.hovered
        onTriggered: {
            if (root.item)
                Notifications.expirePopup(root.item);
        }
    }

    // Everything visual; translated during the dismiss drag.
    Item {
        id: content

        anchors.fill: parent
        x: dragProxy.x
        implicitHeight: cardColumn.implicitHeight + Theme.space[3] * 2 + 4

        // Base card: glass fill, radius 24 all around.
        Rectangle {
            id: cardBase

            anchors.fill: parent
            radius: Theme.space[6]
            color: root.fill

            // Squared bottom-right corner (board: radius 24px 24px 24px 10px).
            // Same-color overlay: interior seams invisible, outer corner cut.
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: Theme.space[6]
                height: Theme.space[6]
                radius: 10
                color: root.fill
            }

            // Top highlight per the floating-glass material rule.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.space[6]
                anchors.rightMargin: Theme.space[6]
                height: 1
                color: Qt.alpha("#FFFFFF", 0.14)
            }
        }

        Column {
            id: cardColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.space[3] + 2
            anchors.rightMargin: Theme.space[4]
            anchors.topMargin: Theme.space[3] + 2
            spacing: Theme.space[2]

            Row {
                width: parent.width
                spacing: Theme.space[3] + 2

                // 48px circular icon: image → app icon → glyph.
                Item {
                    id: iconBox

                    width: Theme.space[8]
                    height: Theme.space[8]
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: iconFill

                        anchors.fill: parent
                        radius: Theme.radiusFull
                        color: root.critical ? Theme.error : Theme.secondaryContainer
                        visible: iconImage.status !== Image.Ready
                    }

                    Image {
                        id: iconImage

                        anchors.fill: parent
                        visible: false // rendered through the mask below
                        source: {
                            if (!root.item)
                                return "";
                            if (root.item.image !== "")
                                return root.item.image.startsWith("/") ? "file://" + root.item.image : root.item.image;
                            if (root.item.appIcon !== "")
                                return Quickshell.iconPath(root.item.appIcon, true);
                            return "";
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Theme.space[8]
                        sourceSize.height: Theme.space[8]
                    }

                    OpacityMask {
                        anchors.fill: parent
                        visible: iconImage.status === Image.Ready
                        source: iconImage
                        maskSource: Rectangle {
                            width: iconBox.width
                            height: iconBox.height
                            radius: Theme.radiusFull
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: iconImage.status !== Image.Ready
                        text: root.critical ? "warning" : "notifications"
                        font.family: "Triton Symbols"
                        font.pixelSize: 24
                        color: root.critical ? Theme.onerror : Theme.onsecondarycontainer
                    }
                }

                Column {
                    width: parent.width - iconBox.width - Theme.space[3] - 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Item {
                        width: parent.width
                        height: summaryText.implicitHeight

                        Text {
                            id: summaryText

                            width: parent.width - timeText.implicitWidth - Theme.space[2]
                            text: root.item ? root.item.summary : ""
                            font.family: Theme.fontUi
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: root.contentColor
                            elide: Text.ElideRight
                        }

                        Text {
                            id: timeText

                            anchors.right: parent.right
                            text: root.item ? root.item.timeLabel(root.now) : ""
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            color: root.subColor
                            anchors.baseline: summaryText.baseline
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.item ? root.item.body : ""
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        color: root.subColor
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        width: parent.width
                        visible: root.item !== null && root.item.appName !== "" && root.item.appName !== root.item.summary
                        text: root.item ? root.item.appName : ""
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        color: root.subColor
                        opacity: 0.7
                        elide: Text.ElideRight
                    }
                }
            }

            // Action row: up to three actions, first one filled primary,
            // the rest veil-on-glass per the material rules.
            Row {
                visible: actionRepeater.count > 0
                spacing: Theme.space[2]

                Repeater {
                    id: actionRepeater

                    model: root.item ? root.item.actions.slice(0, 3) : []

                    delegate: Rectangle {
                        id: actionBtn

                        required property var modelData
                        required property int index
                        readonly property bool primary: index === 0 && !root.critical

                        height: 36
                        radius: Theme.radiusFull
                        width: actionLabel.implicitWidth + Theme.space[4] * 2
                        color: primary ? Theme.primary : Theme.veilBright

                        Text {
                            id: actionLabel

                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, 160)
                            text: actionBtn.modelData && actionBtn.modelData.text ? actionBtn.modelData.text : ""
                            font.family: Theme.fontUi
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: actionBtn.primary ? Theme.onprimary : root.contentColor
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.item) {
                                    root.item.invokeAction(actionBtn.index);
                                    Notifications.expirePopup(root.item);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    // Tap activates the spec's "default" action (board: "tap to open the
    // app"); a rightward drag dismisses the toast.
    MouseArea {
        anchors.fill: parent
        drag.target: dragProxy
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        z: -1 // below the action buttons

        onClicked: {
            if (!root.item)
                return;
            for (let i = 0; i < root.item.actions.length; i++) {
                if (root.item.actions[i] && root.item.actions[i].identifier === "default") {
                    root.item.invokeAction(i);
                    Notifications.expirePopup(root.item);
                    return;
                }
            }
        }
        onReleased: {
            if (root.item && dragProxy.x > root.width / 3)
                Notifications.dismissPopup(root.item);
            dragProxy.x = 0;
        }

        Item {
            id: dragProxy
        }
    }
}
