pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The clipboard panel (Clipboard board): Thick Glass w1000 h780 r36 over a
// 35% scrim, two columns — list w430 and preview. Search field with the
// Super+V hint, round filter chips (ad-hoc, not square t-chips), Pinned and
// Today sections, rows with type discs. Sensitive rows are masked dots with
// a countdown ring. Selected row: solid primary, radius morphs 14→28.
//
// History data is a plain model — the clipboard service (wl-clipboard /
// wtype-data-control) feeds it in production; everything visual is verified
// here with mocks.

Rectangle {
    id: root

    // [{kind: "section", text} | {kind: "row", glyph, fillGlyph?, mono?,
    //   title, meta, pinned?, sensitive?, countdown?, selected?}]
    property var items: []
    property string query: ""
    property int activeChip: 0
    property var chips: ["All", "Text", "Images", "Links", "Code", "Pinned"]

    // Preview.
    property string previewTitle: ""
    property string previewMeta: ""
    property bool previewIsImage: false

    signal pasted(int idx)
    signal paste()
    signal copyAsFile()
    signal pinToggled()
    signal deleteItem()
    signal chipClicked(int idx)
    signal queryEdited(string text)

    width: 1000
    height: 780
    radius: 36
    color: Theme.thickGlassBg
    clip: true

    Row {
        x: 22
        y: 22
        width: parent.width - 44
        height: parent.height - 44
        spacing: 20

        // ---- List column ----
        Column {
            width: 430
            height: parent.height
            spacing: 0

            // Search field.
            Rectangle {
                width: parent.width
                height: 52
                radius: 26
                color: Theme.veilMid

                Row {
                    x: 18
                    height: parent.height
                    spacing: 12

                    TritonIcon {
                        glyph: Icons.search
                        size: 22
                        color: Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        width: 280
                        height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "Google Sans Flex"
                        font.pixelSize: 15
                        color: Theme.onsurface
                        clip: true
                        onTextEdited: root.queryEdited(text)

                        TritonText {
                            visible: parent.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search clipboard"
                            font.pixelSize: 15
                            color: Theme.onsurface
                            opacity: 0.75
                        }
                    }
                }

                TritonText {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Super+V"
                    font.pixelSize: 12
                    color: Theme.onsurface
                    opacity: 0.7
                }
            }

            Item { width: 1; height: 12 }

            // Filter chips: round h36 r18 (ad-hoc per the board note).
            Row {
                spacing: 6

                Repeater {
                    model: root.chips

                    delegate: Rectangle {
                        id: chipDelegate
                        required property string modelData
                        required property int index
                        height: 36
                        width: chipLabel.implicitWidth + 32
                        radius: 18
                        color: index === root.activeChip ? Theme.secondaryContainer : "transparent"
                        border.width: index === root.activeChip ? 0 : 1
                        border.color: Theme.veilHigh

                        TritonText {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chipDelegate.modelData
                            weight: TritonText.Weight.Medium
                            font.pixelSize: 13
                            color: index === root.activeChip ? Theme.onsecondarycontainer : Theme.onsurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.chipClicked(index)
                        }
                    }
                }
            }

            Item { width: 1; height: 6 }

            // Sections + rows.
            Column {
                width: parent.width
                spacing: 3

                Repeater {
                    model: root.items

                    delegate: Item {
                        id: itemDelegate
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: modelData.kind === "section" ? 34 : 60

                        // Section eyebrow.
                        TritonText {
                            visible: modelData.kind === "section"
                            x: 12
                            y: 12
                            text: modelData.text || ""
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            font.letterSpacing: 1.4
                            font.capitalization: Font.AllUppercase
                            color: Theme.onsurface
                            opacity: 0.75
                        }

                        // Row.
                        Item {
                            id: rowRoot
                            visible: modelData.kind !== "section"
                            width: parent.width
                            height: 60
                            property bool isSelected: modelData.selected === true

                            Rectangle {
                                anchors.fill: parent
                                radius: rowRoot.isSelected ? 28 : 14
                                color: parent.isSelected ? Theme.primary : "#0FFFFFFF"
                            }

                            Row {
                                x: 12
                                height: parent.height
                                spacing: 14

                                // Type disc.
                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 19
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: rowRoot.isSelected ? "#26002D6E" : Theme.veilMid

                                    TritonIcon {
                                        anchors.centerIn: parent
                                        glyph: modelData.glyph || Icons.description
                                        fill: modelData.fillGlyph === true
                                        size: 20
                                        color: rowRoot.isSelected ? Theme.onprimary : Theme.onsurface
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    width: 280

                                    TritonText {
                                        text: modelData.title || ""
                                        weight: TritonText.Weight.Medium
                                        font.pixelSize: 14
                                        font.family: modelData.mono ? "JetBrains Mono Medium" : "Google Sans Flex Medium"
                                        color: rowRoot.isSelected ? Theme.onprimary : Theme.onsurface
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    TritonText {
                                        text: modelData.meta || ""
                                        font.pixelSize: 12
                                        color: rowRoot.isSelected ? Theme.onprimary : Theme.onsurface
                                        opacity: 0.75
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Trailing: pin icon or countdown ring.
                            TritonIcon {
                                visible: modelData.pinned === true
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                glyph: Icons.pushPin
                                fill: true
                                size: 18
                                color: Theme.onsurface
                                opacity: 0.8
                            }

                            Item {
                                visible: modelData.countdown !== undefined
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 34

                                // Countdown ring: the wavy ring, tertiary.
                                WavyRing {
                                    anchors.fill: parent
                                    size: 34
                                    thickness: 3
                                    color: Theme.tertiary
                                }

                                TritonText {
                                    anchors.centerIn: parent
                                    text: modelData.countdown || ""
                                    family: TritonText.Family.Mono
                                    weight: TritonText.Weight.SemiBold
                                    font.pixelSize: 11
                                    color: Theme.onsurface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pasted(index)
                            }
                        }
                    }
                }
            }
        }

        // ---- Preview column ----
        Rectangle {
            width: parent.width - 430 - 20
            height: parent.height
            radius: 26
            color: "#2E000000"

            Column {
                x: 14
                y: 14
                width: parent.width - 28
                height: parent.height - 28
                spacing: 0

                // Preview visual: image thumbnail or text preview.
                Rectangle {
                    width: parent.width
                    height: parent.height - 158
                    radius: 22
                    color: "#B3181B21"
                    border.width: 1
                    border.color: "#26FFFFFF"
                    clip: true

                    Image {
                        visible: root.previewIsImage
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../board-wallpaper-1646.jpg")
                        fillMode: Image.PreserveAspectCrop
                    }

                    Column {
                        visible: !root.previewIsImage
                        x: 16
                        y: 16
                        spacing: 8

                        Repeater {
                            model: 6
                            Rectangle {
                                required property int index
                                width: [160, 340, 280, 310, 200, 240][index]
                                height: 10
                                radius: 5
                                color: "#40E2E2E9"
                            }
                        }
                    }
                }

                Column {
                    x: 4
                    topPadding: 14
                    spacing: 2
                    width: parent.width

                    TritonText {
                        text: root.previewTitle
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 15
                        color: Theme.onsurface
                        width: parent.width - 8
                        elide: Text.ElideRight
                    }
                    TritonText {
                        text: root.previewMeta
                        font.pixelSize: 13
                        color: Theme.onsurface
                        opacity: 0.75
                        width: parent.width - 8
                        elide: Text.ElideRight
                    }
                }

                Item { width: 1; height: 12 }

                // Action row.
                Row {
                    spacing: 8

                    Rectangle {
                        height: 48
                        width: pasteRow.implicitWidth + 40
                        radius: 24
                        color: Theme.primary

                        Row {
                            id: pasteRow
                            anchors.centerIn: parent
                            spacing: 8

                            TritonIcon {
                                glyph: Icons.contentPaste
                                fill: true
                                size: 20
                                color: Theme.onprimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            TritonText {
                                text: "Paste"
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 14
                                color: Theme.onprimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.paste()
                        }
                    }

                    Rectangle {
                        height: 48
                        width: copyRow.implicitWidth + 40
                        radius: 24
                        color: Theme.veilMid

                        Row {
                            id: copyRow
                            anchors.centerIn: parent
                            spacing: 8

                            TritonIcon {
                                glyph: Icons.fileCopy
                                size: 20
                                color: Theme.onsurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            TritonText {
                                text: "Copy as file"
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 14
                                color: Theme.onsurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyAsFile()
                        }
                    }

                    IconButton {
                        icon: Icons.pushPin
                        size: 48
                        iconSize: 24
                        fill: Theme.veil
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: root.pinToggled()
                    }

                    IconButton {
                        icon: Icons.deleteIcon
                        size: 48
                        iconSize: 24
                        fill: Theme.veil
                        contentColor: Theme.error
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: root.deleteItem()
                    }
                }
            }
        }
    }
}
