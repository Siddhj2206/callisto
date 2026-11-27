pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The lock screen (Lock board): blurred wallpaper + blue tint. Top center:
// date then the giant Jost clock. Calendar pill under it. Hidden-content
// notification rows bottom-left. Login card centered low — wave avatar,
// name, password field with eye + go button. Media pill
// bottom-right with the status pill below it.
//
// Auth is out of scope here: the leaf exposes passwordSubmitted and the
// field states (idle/typing/wrong/unlocking) as properties — the session
// service drives them.

Item {
    id: root

    enum FieldState { Idle, Typing, Wrong, Unlocking }

    property string dateText: ""
    property string timeText: ""
    property string userName: ""
    property string userInitials: ""
    property string lockedText: ""
    property string calendarText: ""
    property bool hasCalendar: false
    property int fieldState: LockScreen.FieldState.Typing
    property var notifications: [] // [{app, type, glyph, discColor, discContentColor}]
    property string mediaTitle: ""
    property string mediaArtist: ""
    property bool mediaPlaying: false
    property string batteryText: ""
    property string layoutText: "US"

    signal passwordSubmitted(string pw)
    signal mediaToggle()

    // ---- Top center: date + clock + calendar pill ----
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 86
        spacing: 0

        TritonText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            weight: TritonText.Weight.Medium
            font.pixelSize: 26
            color: Theme.onsurface
        }

        TritonText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 250
            font.letterSpacing: -10
            lineHeight: 0.92
            color: Theme.onsurface
        }
    }

    Rectangle {
        visible: root.hasCalendar
        anchors.horizontalCenter: parent.horizontalCenter
        y: 424
        height: 44
        width: calRow.implicitWidth + 34
        radius: 22
        color: Theme.glassBg

        Row {
            id: calRow
            anchors.centerIn: parent
            spacing: 8

            TritonIcon {
                glyph: Icons.event
                size: 22
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: root.calendarText
                weight: TritonText.Weight.Medium
                font.pixelSize: 14
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- Bottom-left: hidden-content notifications ----
    Column {
        x: 68
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 86
        width: 380
        spacing: 8

        Row {
            spacing: 6
            leftPadding: 4
            bottomPadding: 4

            TritonIcon {
                glyph: Icons.visibilityOff
                size: 14
                color: Theme.onsurfacevariant
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: root.notifications.length + " NOTIFICATIONS · CONTENT HIDDEN"
                weight: TritonText.Weight.Medium
                font.pixelSize: 11
                font.letterSpacing: 1.2
                color: Theme.onsurfacevariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Repeater {
            model: root.notifications

            delegate: Item {
                required property var modelData
                width: parent.width
                height: 64

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: Theme.glassBg
                }

                Row {
                    x: 12
                    height: parent.height
                    spacing: 14

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.discColor || Theme.secondaryContainer

                        TritonIcon {
                            anchors.centerIn: parent
                            glyph: modelData.glyph || Icons.notifications
                            fill: true
                            size: 20
                            color: modelData.discContentColor || Theme.onsecondarycontainer
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        TritonText {
                            text: modelData.app || ""
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 15
                            color: Theme.onsurface
                        }
                        TritonText {
                            text: modelData.type || ""
                            font.pixelSize: 13
                            color: Theme.onsurfacevariant
                        }
                    }
                }
            }
        }
    }

    // ---- Login card ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 116
        width: 420
        height: loginCol.implicitHeight + 50
        radius: 32
        color: Theme.glassBg

        Column {
            id: loginCol
            x: 28
            y: 26
            width: parent.width - 56
            spacing: 0

            // Wave avatar with initials.
            Item {
                width: 96
                height: 96
                anchors.horizontalCenter: parent.horizontalCenter

                WaveShape {
                    anchors.fill: parent
                    size: 96
                    color: Theme.tertiaryContainer
                }
                TritonText {
                    anchors.centerIn: parent
                    text: root.userInitials
                    family: TritonText.Family.Display
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 34
                    color: Theme.ontertiarycontainer
                }
            }

            Item { width: 1; height: 16 }

            TritonText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                family: TritonText.Family.Display
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 34
                color: Theme.onsurface
            }

            TritonText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.lockedText
                font.pixelSize: 13
                color: Theme.onsurfacevariant
                topPadding: 4
            }

            Item { width: 1; height: 18 }

            // Password field: h56 r28 white/.12, primary ring when typing,
            // error palette when wrong.
            Rectangle {
                width: parent.width
                height: 56
                radius: 28
                color: root.fieldState === LockScreen.FieldState.Wrong ? "#B893000A" : Theme.veilMid
                border.width: root.fieldState === LockScreen.FieldState.Typing || root.fieldState === LockScreen.FieldState.Wrong ? 2 : 0
                border.color: root.fieldState === LockScreen.FieldState.Wrong ? Theme.error : Theme.primary

                Row {
                    x: 18
                    height: parent.height
                    spacing: 12

                    TritonIcon {
                        glyph: Icons.lock
                        size: 20
                        color: Theme.onsurfacevariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: pwInput
                        focus: true
                        width: parent.parent.width - 18 - 20 - 44 - 40 - 36 - 36
                        height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        font.pixelSize: 22
                        font.letterSpacing: 4
                        color: Theme.onsurface
                        clip: true
                        onAccepted: {
                            root.passwordSubmitted(pwInput.text);
                            pwInput.text = "";
                        }
                        onTextChanged: if (text !== "") root.fieldState = LockScreen.FieldState.Typing
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    height: parent.height
                    spacing: 4

                    TritonIcon {
                        glyph: Icons.visibility
                        size: 20
                        color: Theme.onsurfacevariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.fieldState === LockScreen.FieldState.Typing ? Theme.primary : "#1FE2E2E9"

                        TritonIcon {
                            anchors.centerIn: parent
                            glyph: Icons.arrowForward
                            size: 22
                            color: root.fieldState === LockScreen.FieldState.Typing ? Theme.onprimary : "#61E2E2E9"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.passwordSubmitted(pwInput.text)
                        }
                    }
                }
            }
        }
    }

    // ---- Media pill bottom-right ----
    Rectangle {
        visible: root.mediaTitle !== ""
        anchors.right: parent.right
        anchors.rightMargin: 68
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 156
        width: 360
        height: 64
        radius: 32
        color: Theme.glassBg

        Row {
            x: 12
            height: parent.height
            spacing: 12

            WaveShape {
                size: 40
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.tertiaryContainer
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: 190

                TritonText {
                    text: root.mediaTitle
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 14
                    color: Theme.onsurface
                    elide: Text.ElideRight
                    width: parent.width
                }
                TritonText {
                    text: root.mediaArtist
                    font.pixelSize: 12
                    color: Theme.onsurfacevariant
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: 14
            color: Theme.primary

            TritonIcon {
                anchors.centerIn: parent
                glyph: root.mediaPlaying ? Icons.pause : Icons.playArrow
                fill: true
                size: 24
                color: Theme.onprimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mediaToggle()
            }
        }
    }

    // ---- Status pill bottom-right corner ----
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 68
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 86
        height: 56
        width: statusRow.implicitWidth + 44
        radius: 28
        color: Theme.glassBg

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 20

            TritonIcon {
                glyph: Icons.wifi
                size: 22
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                TritonIcon {
                    glyph: Icons.battery5Bar
                    size: 22
                    color: Theme.onsurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                TritonText {
                    text: root.batteryText
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 14
                    color: Theme.onsurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            TritonText {
                text: root.layoutText
                family: TritonText.Family.Mono
                font.pixelSize: 13
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
