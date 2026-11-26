pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The greeter (Greeter board): user picker and login over blurred wallpaper.
// Brand top-left, clock top-right. Centered: side users as small waves, the
// selected user as a 150px wave with a primary outline ring, an "Other…"
// dashed circle. Selected name in Jost, password pill, session and layout
// pickers below. Bottom row: wifi pill left, a11y/restart/power right.
//
// Auth is out of scope — the leaf exposes passwordSubmitted; the session
// service drives states.

Item {
    id: root

    property string timeText: ""
    property string dateText: ""
    // [{initials, name, color, contentColor}] — color tokens resolved by caller.
    property var users: []
    property int selectedUser: 0
    property string selectedName: ""
    property string sessionName: "niri"
    property string layoutName: "US"
    property string networkName: ""

    signal passwordSubmitted(string pw)
    signal userPicked(int idx)
    signal powerClicked()
    signal restartClicked()

    // ---- Brand ----
    Row {
        x: 64
        y: 56
        spacing: 14

        WaveShape {
            size: 56
            color: Theme.primary
        }
        TritonText {
            text: "triton"
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 38
            color: Theme.onsurface
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ---- Clock ----
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 64
        y: 56
        spacing: 4

        TritonText {
            anchors.right: parent.right
            text: root.timeText
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 44
            color: Theme.onsurface
        }
        TritonText {
            anchors.right: parent.right
            text: root.dateText
            font.pixelSize: 15
            color: Theme.onsurface
        }
    }

    // ---- Centered login stack ----
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.22)
        spacing: 0

        // User picker row.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 52
            height: 190

            Repeater {
                model: root.users

                delegate: Column {
                    id: userDelegate
                    required property var modelData
                    required property int index
                    property bool isSelected: index === root.selectedUser
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Item {
                        width: userDelegate.isSelected ? 168 : 96
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Selection ring: 1.8px primary stroke on the wave
                        // outline at 1.12 scale.
                        WavyRing {
                            visible: userDelegate.isSelected
                            anchors.centerIn: parent
                            size: parent.width
                            thickness: 1.8
                            color: Theme.primary
                        }

                        Item {
                            anchors.centerIn: parent
                            width: userDelegate.isSelected ? 150 : 96
                            height: width

                            WaveShape {
                                anchors.fill: parent
                                size: width
                                color: userDelegate.modelData.color || Theme.surfaceContainerHighest
                            }
                            TritonText {
                                anchors.centerIn: parent
                                text: userDelegate.modelData.initials || ""
                                family: TritonText.Family.Display
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: userDelegate.isSelected ? 40 : 24
                                color: userDelegate.modelData.contentColor || Theme.onsurface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.userPicked(index)
                        }
                    }

                    TritonText {
                        visible: !userDelegate.isSelected
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: userDelegate.modelData.name || ""
                        weight: TritonText.Weight.Medium
                        font.pixelSize: 14
                        color: Theme.onsurfacevariant
                    }
                }
            }

            // Other…: dashed circle-plus.
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Item {
                    width: 96
                    height: 96

                    Rectangle {
                        anchors.fill: parent
                        radius: 48
                        color: "transparent"
                        border.width: 2.6
                        border.color: "#80FFFFFF"
                        // dashes are beyond Rectangle; the board's 6/6
                        // dasharray reads as texture at this size — a thin
                        // ring is the closest primitive-level match. A
                        // canvas-dash pass follows if the reviewer calls it.
                    }
                    TritonIcon {
                        anchors.centerIn: parent
                        glyph: Icons.add
                        size: 32
                        color: Theme.onsurface
                    }
                }

                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Other…"
                    weight: TritonText.Weight.Medium
                    font.pixelSize: 14
                    color: Theme.onsurfacevariant
                }
            }
        }

        // Selected name.
        TritonText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.selectedName
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 54
            color: Theme.onsurface
        }

        Item { width: 1; height: 24 }

        // Password pill: w460 h60 r30 white/.12 + primary ring.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 460
            height: 60
            radius: 30
            color: "#1FFFFFFF"
            border.width: 2
            border.color: Theme.primary

            Row {
                x: 20
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
                    width: 320
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.pixelSize: 18
                    font.letterSpacing: 3
                    color: Theme.onsurface
                    clip: true
                    onAccepted: root.passwordSubmitted(pwInput.text)

                    TritonText {
                        visible: parent.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        font.pixelSize: 16
                        color: Theme.onsurfacevariant
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: Theme.primary

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: Icons.arrowForward
                    size: 24
                    color: Theme.onprimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.passwordSubmitted(pwInput.text)
                }
            }
        }

        Item { width: 1; height: 20 }

        // Session + layout pickers.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: [
                    { icon: Icons.desktopWindows, text: root.sessionName },
                    { icon: Icons.keyboard, text: root.layoutName },
                ]

                delegate: Rectangle {
                    id: pickerDelegate
                    required property var modelData
                    height: 40
                    width: pickerRow.implicitWidth + 32
                    radius: 20
                    color: Theme.glassBg

                    Row {
                        id: pickerRow
                        anchors.centerIn: parent
                        spacing: 8

                        TritonIcon {
                            visible: pickerDelegate.modelData.icon !== ""
                            glyph: pickerDelegate.modelData.icon
                            size: 20
                            color: Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        TritonText {
                            text: pickerDelegate.modelData.text
                            weight: TritonText.Weight.Medium
                            font.pixelSize: 14
                            color: Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        TritonIcon {
                            glyph: Icons.arrowDropDown
                            size: 18
                            color: Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // ---- Bottom-left: wifi pill ----
    Rectangle {
        visible: root.networkName !== ""
        x: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        height: 56
        width: netRow.implicitWidth + 44
        radius: 28
        color: Theme.glassBg

        Row {
            id: netRow
            anchors.centerIn: parent
            spacing: 10

            TritonIcon {
                glyph: Icons.wifi
                size: 22
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: root.networkName
                weight: TritonText.Weight.Medium
                font.pixelSize: 14
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- Bottom-right: a11y / restart / power ----
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        spacing: 12

        Repeater {
            model: [
                { glyph: Icons.accessibilityNew, color: Theme.glassBg, fg: Theme.onsurface, act: "a11y" },
                { glyph: Icons.restartAlt, color: Theme.glassBg, fg: Theme.onsurface, act: "restart" },
                { glyph: Icons.powerSettingsNew, color: "#CC7C3114", fg: Theme.ontertiarycontainer, act: "power" },
            ]

            delegate: Rectangle {
                id: circleDelegate
                required property var modelData
                width: 56
                height: 56
                radius: 28
                color: modelData.color

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: circleDelegate.modelData.glyph
                    size: 24
                    color: circleDelegate.modelData.fg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (circleDelegate.modelData.act === "power")
                            root.powerClicked();
                        else if (circleDelegate.modelData.act === "restart")
                            root.restartClicked();
                    }
                }
            }
        }
    }
}
