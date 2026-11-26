pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../services"
import ".."

// The wallpaper dock (Wallpaper board): thick glass r36, padding 22/26/20.
// Top row: collection tabs (Pictures/Triton/Dynamic/Colors) + Applying-to
// segment. Thumbnail strip: 200x120 r20 cards, selected scales 1.04 with
// primary ring + check disc. Bottom hint row with mono key chips.

Rectangle {
    id: root

    property var wallpapers: []
    property int selected: 0
    property int applied: 0

    signal selected(int idx)
    signal committed(int idx)

    height: 260
    radius: 36
    color: Theme.thickGlassBg

    // ---- Tab row ----
    Row {
        x: 26
        y: 22
        height: 40
        spacing: 8

        Repeater {
            model: [
                { glyph: Icons.apps, label: "Pictures", active: true },
                { glyph: Icons.apps, label: "Triton", active: false },
                { glyph: Icons.schedule, label: "Dynamic", active: false },
                { glyph: Icons.palette, label: "Colors", active: false },
            ]

            delegate: Rectangle {
                id: tabDelegate
                required property var modelData
                height: 40
                width: tabRow.implicitWidth + 36
                radius: 20
                color: modelData.active ? Theme.primary : "transparent"
                border.width: modelData.active ? 0 : 1
                border.color: Theme.veilHigh

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 8

                    TritonIcon {
                        glyph: tabDelegate.modelData.glyph
                        fill: tabDelegate.modelData.active
                        size: 20
                        color: tabDelegate.modelData.active ? Theme.onprimary : "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonText {
                        text: tabDelegate.modelData.label
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 14
                        color: tabDelegate.modelData.active ? Theme.onprimary : "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ---- Applying-to segment ----
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 26
        y: 22
        height: 40
        spacing: 12

        TritonText {
            text: "Applying to"
            font.pixelSize: 13
            color: "#FFFFFF"
            opacity: 0.75
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            height: 40
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: ["Desktop", "+ Lock", "+ Greeter"]

                delegate: Rectangle {
                    id: segDelegate
                    required property string modelData
                    required property int index
                    property bool on: index === 0
                    height: 40
                    width: segLabel.implicitWidth + 32
                    radius: index === 0 ? 20 : 20
                    color: on ? Theme.primary : Theme.veilMid

                    TritonText {
                        id: segLabel
                        anchors.centerIn: parent
                        text: segDelegate.modelData
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 14
                        color: segDelegate.on ? Theme.onprimary : "#FFFFFF"
                    }
                }
            }
        }
    }

    // ---- Thumbnail strip ----
    Row {
        x: 26
        y: 84
        spacing: 18

        Repeater {
            model: root.wallpapers

            delegate: Column {
                id: thumbDelegate
                required property var modelData
                required property int index
                property bool isSelected: root.selected === index
                spacing: 8

                Rectangle {
                    width: 200
                    height: 120
                    radius: 20
                    scale: thumbDelegate.isSelected ? 1.04 : 1.0
                    border.width: thumbDelegate.isSelected ? 3 : 0
                    border.color: Theme.primary
                    clip: true

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    WallpaperThumb {
                        anchors.fill: parent
                        kind: thumbDelegate.modelData.kind
                        path: thumbDelegate.modelData.path || ""
                    }

                    // Check disc on the applied wallpaper.
                    Rectangle {
                        visible: root.applied === thumbDelegate.index
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.primary

                        TritonIcon {
                            anchors.centerIn: parent
                            glyph: Icons.check
                            fill: true
                            size: 18
                            color: Theme.onprimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected(thumbDelegate.index)
                        onDoubleClicked: root.committed(thumbDelegate.index)
                    }
                }

                TritonText {
                    x: 4
                    text: thumbDelegate.modelData.name
                    weight: thumbDelegate.isSelected ? TritonText.Weight.SemiBold : TritonText.Weight.Medium
                    font.pixelSize: 13
                    color: "#FFFFFF"
                    opacity: thumbDelegate.isSelected ? 1.0 : 0.8
                }
            }
        }
    }

    // ---- Key hints ----
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        spacing: 22

        Repeater {
            model: [
                { keys: "← →", action: "browse" },
                { keys: "Enter", action: "set" },
                { keys: "Esc", action: "revert" },
            ]

            delegate: Row {
                required property var modelData
                spacing: 8

                Rectangle {
                    height: 24
                    width: Math.max(24, keyLabel.implicitWidth + 12)
                    radius: 7
                    color: "transparent"
                    border.width: 1
                    border.color: "#59FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter

                    TritonText {
                        id: keyLabel
                        anchors.centerIn: parent
                        text: modelData.keys
                        family: TritonText.Family.Mono
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 12
                        color: "#FFFFFF"
                    }
                }
                TritonText {
                    text: modelData.action
                    font.pixelSize: 13
                    color: "#FFFFFF"
                    opacity: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
