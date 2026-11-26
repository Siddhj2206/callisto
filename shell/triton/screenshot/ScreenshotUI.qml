pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The capture UI (Screenshot board): dimmed screen with the selection cut
// out — 2px primary border, rule-of-thirds lines, corner and edge handles.
// Size chip follows the selection. Hint pill top-center, glass toolbar
// bottom-center: mode segment, pointer/timer/record buttons, and the 64px
// wave capture button.
//
// Region dragging and actual capture belong to the capture service — this is
// the interactive leaf: mode switching, hover states, selection geometry in
// and out.

Item {
    id: root

    enum Mode { Region, Window, Screen }

    property int mode: ScreenshotUI.Mode.Region
    // Selection rect in screen coordinates.
    property rect selection: Qt.rect(0, 0, 0, 0)
    property string hintSizeText: ""

    signal capture()
    signal modePicked(int m)
    signal cancelled()

    // Dim everywhere except the selection: four scrim rects around it.
    Rectangle { // top
        x: 0; y: 0
        width: root.width
        height: root.selection.y
        color: "#80000000"
    }
    Rectangle { // bottom
        x: 0
        y: root.selection.y + root.selection.height
        width: root.width
        height: root.height - y
        color: "#80000000"
    }
    Rectangle { // left
        x: 0
        y: root.selection.y
        width: root.selection.x
        height: root.selection.height
        color: "#80000000"
    }
    Rectangle { // right
        x: root.selection.x + root.selection.width
        y: root.selection.y
        width: root.width - x
        height: root.selection.height
        color: "#80000000"
    }

    // Selection frame.
    Item {
        x: root.selection.x
        y: root.selection.y
        width: root.selection.width
        height: root.selection.height
        visible: root.selection.width > 0

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: Theme.primary
        }

        // Rule-of-thirds lines.
        Repeater {
            model: 2

            Rectangle {
                required property int index
                x: parent.width * (index + 1) / 3
                width: 1
                height: parent.height
                color: "#38FFFFFF"
            }
        }
        Repeater {
            model: 2

            Rectangle {
                required property int index
                y: parent.height * (index + 1) / 3
                height: 1
                width: parent.width
                color: "#38FFFFFF"
            }
        }

        // Corner handles 26x8 / 8x26.
        Repeater {
            model: [
                { x: -4, y: -4, w: 26, h: 8, ax: -13 }, { x: -4, y: -4, w: 8, h: 26, ay: -13 },
                { x: 1, y: -4, w: 26, h: 8, right: true, ax: -13 }, { x: 1, y: -4, w: 8, h: 26, right: true, ay: -13 },
                { x: -4, y: 1, w: 26, h: 8, bottom: true, ax: -13 }, { x: -4, y: 1, w: 8, h: 26, bottom: true, ay: -13 },
                { x: 1, y: 1, w: 26, h: 8, right: true, bottom: true, ax: -13 }, { x: 1, y: 1, w: 8, h: 26, right: true, bottom: true, ay: -13 },
            ]

            Rectangle {
                required property var modelData
                x: modelData.right ? parent.width - (modelData.w === 26 ? modelData.w - 4 : -4) : modelData.x + (modelData.w === 26 ? 0 : 0)
                y: modelData.bottom ? parent.height - (modelData.h === 26 ? modelData.h - 4 : -4) : modelData.y
                width: modelData.w
                height: modelData.h
                radius: 3
                color: Theme.primary
            }
        }
    }

    // Size chip.
    Rectangle {
        visible: root.hintSizeText !== ""
        x: root.selection.x + root.selection.width / 2 - width / 2
        y: root.selection.y - 48
        height: 36
        width: sizeRow.implicitWidth + 32
        radius: 18
        color: Theme.glassBg

        Row {
            id: sizeRow
            anchors.centerIn: parent
            spacing: 8

            TritonIcon {
                glyph: Icons.crop
                size: 18
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: root.hintSizeText
                family: TritonText.Family.Mono
                weight: TritonText.Weight.Medium
                font.pixelSize: 14
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Hint pill top-center.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        height: 48
        width: hintRow.implicitWidth + 48
        radius: 24
        color: Theme.glassBg

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: 22

            Repeater {
                model: [
                    { key: "Drag", label: "select" },
                    { key: "Space", label: "window" },
                    { key: "Enter", label: "capture" },
                    { key: "Esc", label: "cancel" },
                ]

                Row {
                    id: capHintRow
                    required property var modelData
                    spacing: 8

                    Rectangle {
                        height: 24
                        width: Math.max(24, capKey.implicitWidth + 12)
                        radius: 7
                        color: "transparent"
                        border.width: 1
                        border.color: "#4DFFFFFF"

                        TritonText {
                            id: capKey
                            anchors.centerIn: parent
                            text: capHintRow.modelData.key
                            family: TritonText.Family.Mono
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            color: Theme.onsurface
                        }
                    }

                    TritonText {
                        text: capHintRow.modelData.label
                        font.pixelSize: 13
                        color: Theme.onsurfacevariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // Toolbar bottom-center.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        height: 80
        width: toolbarRow.implicitWidth + 26
        radius: 40
        color: Theme.glassBg

        Row {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 14

            // Mode segment: connected group.
            Row {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        { glyph: Icons.screenshotRegion, label: "Region" },
                        { glyph: Icons.selectWindow, label: "Window" },
                        { glyph: Icons.desktopWindows, label: "Screen" },
                    ]

                    delegate: Rectangle {
                        id: segDelegate
                        required property var modelData
                        required property int index
                        height: 48
                        width: segRow.implicitWidth + 36
                        radius: 24
                        color: root.mode === index ? Theme.primary : Theme.surfaceContainerHigh

                        Row {
                            id: segRow
                            anchors.centerIn: parent
                            spacing: 8

                            TritonIcon {
                                glyph: segDelegate.modelData.glyph
                                size: 20
                                color: root.mode === segDelegate.index ? Theme.onprimary : Theme.onsurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            TritonText {
                                visible: root.mode === segDelegate.index
                                text: segDelegate.modelData.label
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 15
                                color: root.mode === segDelegate.index ? Theme.onprimary : Theme.onsurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.modePicked(segDelegate.index)
                        }
                    }
                }
            }

            // Divider.
            Rectangle {
                width: 1
                height: 36
                color: "#33FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                icon: Icons.adsClick
                size: 48
                iconSize: 24
                fill: Theme.veil
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                icon: Icons.timer
                size: 48
                iconSize: 24
                fill: Theme.veil
                anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
                icon: Icons.videocam
                size: 48
                iconSize: 24
                fill: Theme.veil
                anchors.verticalCenter: parent.verticalCenter
            }

            // Capture: 64px wave button.
            Item {
                width: 64
                height: 64
                anchors.verticalCenter: parent.verticalCenter

                WaveShape {
                    anchors.fill: parent
                    size: 64
                    color: Theme.primary
                }
                TritonIcon {
                    anchors.centerIn: parent
                    glyph: Icons.photoCamera
                    size: 28
                    color: Theme.onprimary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.capture()
                }
            }
        }
    }
}
