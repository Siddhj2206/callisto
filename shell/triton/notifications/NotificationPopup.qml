pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../services"
import ".."

// The notification toast surface, per the Notifications board.
//
// Floating layer-shell panel, top right, below the bar zone. Width 400.
// Shows at most four toasts; the rest collapse into a "N more" pill.
// Toasts slide in on spatial-default motion and fade out.
//
// Instantiate once per screen (see README.md):
//     NotificationPopup { screen: modelData }
PanelWindow {
    id: root

    // Distance below the top edge. The bar is a 56px island in its own
    // exclusion zone; toasts sit under it. Not a token — surface layout.
    property int topMargin: Theme.barHeight + Theme.space[2]

    readonly property int cardWidth: 400 // board: toast column width

    anchors {
        top: true
        right: true
    }

    margins {
        top: root.topMargin
        right: Theme.space[6]
    }

    implicitWidth: cardWidth
    implicitHeight: toastColumn.implicitHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Input region covers only the toast column, never the empty screen.
    mask: Region {
        item: toastColumn
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    visible: toastColumn.implicitHeight > 0

    Column {
        id: toastColumn

        width: root.cardWidth
        spacing: 10 // board: toast stack gap

        Repeater {
            // Newest toasts at the end of popupQueue; render newest first.
            model: {
                const q = Notifications.popupQueue;
                const shown = q.slice(Math.max(0, q.length - Notifications.maxPopups));
                return shown.slice().reverse();
            }

            delegate: NotificationCard {
                id: card

                required property var modelData
                item: modelData
                now: clock.date
                width: root.cardWidth

                // Slide in from the right on spatial default; fade out.
                transform: Translate {
                    id: slideIn

                    x: 0

                    SequentialAnimation on x {
                        running: true
                        NumberAnimation {
                            from: root.cardWidth
                            to: 0
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                opacity: item && item.popup ? 1 : 0
            }
        }

        // Overflow pill: "N more", right-aligned glass chip per the board.
        Rectangle {
            visible: Notifications.overflowCount > 0
            anchors.right: parent.right
            height: 36
            width: pillRow.implicitWidth + Theme.space[4] * 2
            radius: Theme.radiusFull
            color: Theme.glassBg

            Row {
                id: pillRow

                anchors.centerIn: parent
                spacing: Theme.space[2]

                Text {
                    text: "stacks"
                    font.family: "Triton Symbols"
                    font.pixelSize: 18
                    color: Theme.onsurface
                }

                Text {
                    text: Notifications.overflowCount + " more"
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.onsurface
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Surface the oldest hidden toast by expiring a visible one.
                    const q = Notifications.popupQueue;
                    if (q.length > 0)
                        Notifications.expirePopup(q[q.length - 1]);
                }
            }
        }
    }
}
