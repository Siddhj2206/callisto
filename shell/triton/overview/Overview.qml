pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The overview (Overview board): full-screen blurred stage. Workspaces are
// horizontal ribbons of window thumbnails; the active workspace's ribbon
// carries a white/.08 plate bleeding off the right edge. Left edge: 56px
// numbered wave badges with names and counts. Windows are mock-content
// thumbnails with floating name pills; the focused one gets the primary
// ring + halo. Search pill top-center, hints bottom-center.
//
// Window data is mock-shaped — compositor snapshots arrive with the window
// service; structure, navigation and geometry are verified here.

Item {
    id: root

    // [{num, name, count, active}] workspaces
    property var workspaces: []
    // rows: [{workspace, windows: [{app, glyph, kind, focused, floating}]}]
    property var ribbons: []

    signal windowPicked(int ribbon, int idx)
    signal workspacePicked(int idx)
    signal cancelled()

    // ---- Search pill ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 22
        width: 524
        height: 56
        radius: 28
        color: Theme.glassBg

        Row {
            x: 10
            height: parent.height
            spacing: 12

            WaveShape {
                size: 36
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                width: 420
                height: parent.height
                verticalAlignment: TextInput.AlignVCenter
                font.family: "Google Sans Flex"
                font.pixelSize: 16
                color: Theme.onsurface
                clip: true

                TritonText {
                    visible: parent.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Type to launch or jump to a window"
                    font.pixelSize: 16
                    color: Theme.onsurfacevariant
                }
            }
        }
    }

    // ---- Workspace ribbons ----
    Column {
        x: 0
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: 100
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 70
        spacing: 40

        Repeater {
            model: root.ribbons

            delegate: Item {
                id: ribbonDelegate
                required property var modelData
                required property int index
                property var ws: root.workspaces.length > index ? root.workspaces[index] : ({ num: index + 1, name: "", count: 0, active: false })

                width: root.width
                height: 330

                // Active plate.
                Rectangle {
                    visible: ribbonDelegate.ws.active
                    x: 150
                    width: root.width - 150
                    height: parent.height + 16
                    y: -8
                    radius: 32
                    color: "#14FFFFFF"
                }

                // Workspace badge.
                Column {
                    x: 84
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    width: 70

                    Item {
                        width: 56
                        height: 56
                        anchors.horizontalCenter: parent.horizontalCenter

                        WaveShape {
                            anchors.fill: parent
                            size: 56
                            color: ribbonDelegate.ws.active ? Theme.primary : Theme.surfaceContainerHighest
                        }
                        TritonText {
                            anchors.centerIn: parent
                            text: ribbonDelegate.ws.num
                            family: TritonText.Family.Display
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 22
                            color: ribbonDelegate.ws.active ? Theme.onprimary : Theme.onsurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.workspacePicked(ribbonDelegate.index)
                        }
                    }

                    TritonText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ribbonDelegate.ws.name
                        family: TritonText.Family.Display
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 22
                        color: Theme.onsurface
                    }
                    TritonText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ribbonDelegate.ws.count + " windows"
                        font.pixelSize: 12
                        color: Theme.onsurfacevariant
                    }
                }

                // Window thumbnails.
                Row {
                    x: 310
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Repeater {
                        model: ribbonDelegate.modelData.windows || []

                        delegate: Item {
                            id: winDelegate
                            required property var modelData
                            required property int index
                            property bool isFocused: modelData.focused === true

                            width: 270
                            height: 300
                            anchors.verticalCenter: parent.verticalCenter

                            // Ring + halo for the focused window.
                            Rectangle {
                                visible: winDelegate.isFocused
                                anchors.fill: parent
                                anchors.margins: -6
                                radius: 22
                                color: "transparent"
                                border.width: 6
                                border.color: "#40B0C6FF"
                            }
                            Rectangle {
                                visible: winDelegate.isFocused
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: 19
                                color: "transparent"
                                border.width: 3
                                border.color: Theme.primary
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: modelData.dark === false ? "#E8E8EC" : "#C4181B21"
                                clip: true

                                // Mock content lines.
                                Column {
                                    x: 14
                                    y: 14
                                    spacing: 7

                                    Repeater {
                                        model: 12

                                        Rectangle {
                                            required property int index
                                            width: [90, 200, 150, 230, 180, 240, 140, 220, 170, 200, 130, 160][index]
                                            height: 8
                                            radius: 4
                                            color: {
                                                const kind = winDelegate.modelData.kind;
                                                if (kind === "editor")
                                                    return index % 4 === 0 ? "#80B0C6FF" : index % 3 === 0 ? "#80FFB59B" : "#59E2E2E9";
                                                return winDelegate.modelData.dark === false ? "#33333350" : "#3DE2E2E9";
                                            }
                                        }
                                    }
                                }
                            }

                            // Name pill floating at the top corner.
                            Rectangle {
                                x: 10
                                y: 10
                                height: 32
                                width: nameRow.implicitWidth + 24
                                radius: 16
                                color: "#B3000000"

                                Row {
                                    id: nameRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    TritonIcon {
                                        glyph: winDelegate.modelData.glyph || Icons.terminal
                                        size: 16
                                        color: Theme.onsurface
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    TritonText {
                                        text: winDelegate.modelData.app || ""
                                        weight: TritonText.Weight.Medium
                                        font.pixelSize: 13
                                        color: Theme.onsurface
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.windowPicked(ribbonDelegate.index, winDelegate.index)
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Hints pill ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        height: 52
        width: ovHintRow.implicitWidth + 48
        radius: 26
        color: Theme.glassBg

        Row {
            id: ovHintRow
            anchors.centerIn: parent
            spacing: 22

            Repeater {
                model: [
                    { key: "↑↓", label: "workspaces" },
                    { key: "←→", label: "windows" },
                    { key: "Enter", label: "jump" },
                    { key: "Esc", label: "close" },
                ]

                Row {
                    id: ovHint
                    required property var modelData
                    spacing: 8

                    Rectangle {
                        height: 24
                        width: Math.max(24, ovKey.implicitWidth + 12)
                        radius: 7
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.veilHigh

                        TritonText {
                            id: ovKey
                            anchors.centerIn: parent
                            text: ovHint.modelData.key
                            family: TritonText.Family.Mono
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            color: Theme.onsurface
                        }
                    }

                    TritonText {
                        text: ovHint.modelData.label
                        font.pixelSize: 13
                        color: Theme.onsurfacevariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
