pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.tokens
import ".."
import "../components"
import "../services"

// Toast surface: top-right column below the bar zone (Notifications board).
// Width 400, 10px gaps, at most four cards visible — overflow collapses into
// the "N more" pill trailing the column. Each card carries its own 6s expiry
// unless critical; hovering pauses (board timing rules).

PanelWindow {
    id: root

    anchors { top: true; right: true }
    implicitWidth: 400 + 24
    implicitHeight: toastCol.implicitHeight + Metrics.barHeight + Metrics.barTop * 2 + 12
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: NotificationState.toasts.length > 0

    // Clicks pass through everywhere except the actual toast cards —
    // the strip window otherwise eats the whole top-right screen corner.
    mask: Region { item: toastCol }

    Column {
        id: toastCol
        x: 0
        y: Metrics.barHeight + Metrics.barTop * 2 // clear the bar
        width: 400
        spacing: 10

        Repeater {
            model: NotificationState.toasts.slice(0, 4)

            delegate: Item {
                required property var modelData
                width: 400
                height: card.implicitHeight

                NotificationCard {
                    id: card
                    width: 400
                    kind: modelData.critical ? NotificationCard.Kind.Critical
                         : modelData.replyable ? NotificationCard.Kind.Message
                         : modelData.progress >= 0 ? NotificationCard.Kind.Progress
                         : NotificationCard.Kind.Standard
                    initials: modelData.initials || ""
                    iconGlyph: modelData.iconGlyph || Icons.notifications
                    title: modelData.title || ""
                    timeText: modelData.time || ""
                    body: modelData.preview || ""
                    hasReply: modelData.replyable || false
                    progress: modelData.progress !== undefined ? modelData.progress : -1
                    progressText: modelData.progressText || ""
                    actions: modelData.actions || []

                    onClicked: NotificationState.dismissToast(modelData)
                }

                // Per-card expiry: 6s, paused while hovered, criticals never.
                Timer {
                    running: modelData.critical !== true && !hoverArea.containsMouse
                    interval: 6000
                    onTriggered: NotificationState.dismissToast(modelData)
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPressed: mouse => mouse.accepted = false
                }
            }
        }

        // Overflow pill.
        Item {
            visible: NotificationState.toasts.length > 4
            width: 400
            height: visible ? 36 : 0

            Rectangle {
                anchors.right: parent.right
                height: 36
                width: moreRow.implicitWidth + 32
                radius: 18
                color: Theme.glassBg

                Row {
                    id: moreRow
                    anchors.centerIn: parent
                    spacing: 8

                    TritonIcon {
                        glyph: Icons.stacks
                        size: 18
                        color: Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonText {
                        text: (NotificationState.toasts.length - 4) + " more"
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 13
                        color: Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
