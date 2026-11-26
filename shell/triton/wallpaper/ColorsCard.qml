pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../services"
import ".."

// Colors card (Wallpaper board): glass, w370 r32. Five wave swatches for the
// wallpaper's regions, four theme-color chips (primary, surface, tertiary,
// background), and the mica explanation line. Values read live from Theme so
// a live preview re-themes the card as the engine applies.

Rectangle {
    id: root

    width: 370
    height: cardColumn.implicitHeight + 40
    radius: 32
    color: Theme.glassBg

    readonly property var regions: [
        { name: "Planet", color: "#3C5FD6" },
        { name: "Hull", color: "#C8D2E8" },
        { name: "Rock", color: "#E8763B" },
        { name: "Shadow", color: "#23262E" },
        { name: "Haze", color: "#7BC4B8" },
    ]

    Column {
        id: cardColumn
        x: 22
        y: 20
        width: parent.width - 44
        spacing: 0

        Row {
            height: 28
            spacing: 10

            TritonIcon {
                glyph: Icons.palette
                fill: true
                size: 20
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: "Colors from Orbit"
                family: TritonText.Family.Display
                weight: TritonText.Weight.Medium
                font.pixelSize: 20
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: 1; height: 1; }
            Rectangle {
                visible: true
                height: 22
                width: liveTag.implicitWidth + 20
                radius: 10
                color: Theme.tertiaryContainer
                anchors.verticalCenter: parent.verticalCenter

                TritonText {
                    id: liveTag
                    anchors.centerIn: parent
                    text: "Live preview"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 12
                    font.letterSpacing: 0.5
                    color: Theme.ontertiarycontainer
                }
            }
        }

        Item { width: 1; height: 16 }

        // Region swatches: five waves with names.
        Row {
            width: parent.width
            height: 62

            Repeater {
                model: root.regions

                delegate: Column {
                    required property var modelData
                    width: parent.width / 5
                    spacing: 6

                    WaveShape {
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 40
                        color: modelData.color
                    }
                    TritonText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        font.pixelSize: 11
                        color: "#FFFFFF"
                        opacity: 0.85
                    }
                }
            }
        }

        Item { width: 1; height: 14 }

        // Theme color chips: connected group, first/last rounded.
        Row {
            width: parent.width
            height: 36
            spacing: 6

            Repeater {
                model: [
                    { color: Theme.primary, first: true, last: false },
                    { color: Theme.surfaceContainerHigh, first: false, last: false },
                    { color: Theme.tertiary, first: false, last: false },
                    { color: Theme.surface, first: false, last: true, ring: true },
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 18) / 4
                    height: 36
                    radius: modelData.first ? 18 : modelData.last ? 18 : 6
                    color: modelData.color
                    border.width: modelData.ring ? 1 : 0
                    border.color: "#4DFFFFFF"

                    Rectangle {
                        visible: modelData.first
                        anchors.right: parent.right
                        width: 12
                        height: parent.height
                        color: parent.color
                    }
                    Rectangle {
                        visible: modelData.last
                        anchors.left: parent.left
                        width: 12
                        height: parent.height
                        color: parent.color
                    }
                }
            }
        }

        Item { width: 1; height: 14 }

        Row {
            width: parent.width
            spacing: 8

            TritonIcon {
                glyph: Icons.info
                size: 18
                color: Theme.primary
            }
            TritonText {
                width: parent.width - 26
                text: "The hull is bright. Mica gets about 8% more tint so text stays above 4.5:1."
                font.pixelSize: 13
                lineHeight: 1.45
                color: "#FFFFFF"
                opacity: 0.85
                wrapMode: Text.WordWrap
            }
        }
    }
}
