pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The window switcher (WindowSwitcher board): Thick Glass centered panel
// w1212 r36 over a 35% scrim. Header shows the focused window's title and
// recency meta; the card row shows every window as a 220px card with its
// thumbnail, app disc and workspace. Selection: primary-container fill, 3px
// primary inset ring, shadow, scale 1.04.
//
// Thumbnails are mock lines here — real snapshots come from the compositor
// (Hyprland toplevel export), wired with the window service.

Rectangle {
    id: root

    // [{title, app, workspace, glyph, fillGlyph?, attention?, floating?,
    //   thumbKind: "lines"|"editor"|"solid"|"chat"|"bars"}]
    property var windows: []
    property int selected: 1
    property string headerTitle: ""
    property string headerMeta: ""

    signal activated(int idx)
    signal cancel()

    width: 1212
    radius: 36
    color: Theme.thickGlassBg
    implicitHeight: wsCol.implicitHeight + 44
    clip: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) {
            selected = (selected + 1) % windows.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab) {
            selected = (selected - 1 + windows.length) % windows.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            cancel();
            event.accepted = true;
        }
    }

    Column {
        id: wsCol
        x: 24
        y: 24
        width: parent.width - 48
        spacing: 16

        // Header.
        Item {
            width: parent.width
            height: 44

            Column {
                spacing: 4

                TritonText {
                    text: root.headerTitle
                    family: TritonText.Family.Display
                    weight: TritonText.Weight.Medium
                    font.pixelSize: 28
                    color: Theme.onsurface
                }
                TritonText {
                    text: root.headerMeta
                    font.pixelSize: 13
                    color: Theme.onsurface
                    opacity: 0.8
                }
            }

            TritonText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: (root.selected + 1) + " of " + root.windows.length
                font.pixelSize: 13
                color: Theme.onsurface
                opacity: 0.8
            }
        }

        // Card row.
        Row {
            spacing: 16
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: root.windows

                delegate: Item {
                    id: cardDelegate
                    required property var modelData
                    required property int index
                    property bool isSelected: index === root.selected

                    width: 220
                    height: 220 * (isSelected ? 1.04 : 1.0) * 0.86
                    scale: isSelected ? 1.04 : 1.0

                    Behavior on scale { NumberAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: cardDelegate.isSelected ? Theme.primaryContainer : "#0FFFFFFF"
                        border.width: cardDelegate.isSelected ? 3 : 0
                        border.color: Theme.primary

                        Column {
                            x: 10
                            y: 10
                            width: parent.width - 20
                            spacing: 8

                            // Thumbnail: 200x124 r14 — mock content lines by kind.
                            Rectangle {
                                width: 200
                                height: 124
                                radius: 14
                                color: "#B3181B21"
                                border.width: 1
                                border.color: "#1AFFFFFF"
                                clip: true

                                Column {
                                    x: 12
                                    y: 12
                                    spacing: 6

                                    Repeater {
                                        model: cardDelegate.modelData.thumbKind === "solid" ? 0 : 5

                                        Rectangle {
                                            required property int index
                                            width: [100, 176, 140, 160, 120][index % 5]
                                            height: 8
                                            radius: 4
                                            color: {
                                                const kind = cardDelegate.modelData.thumbKind;
                                                if (kind === "editor")
                                                    return index === 0 ? "#B0C6FF" : index === 1 ? "#FFB59B" : "#4DE2E2E9";
                                                if (kind === "chat")
                                                    return index % 2 ? "#3DE2E2E9" : "#59B0C6FF";
                                                if (kind === "bars")
                                                    return index === 0 ? "#FFB59B" : "#45B0C6FF";
                                                return "#3DE2E2E9";
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: cardDelegate.modelData.thumbKind === "solid"
                                    x: 12
                                    y: 12
                                    width: 176
                                    height: 24
                                    radius: 6
                                    color: "#B000429B"
                                }

                                // Floating tag.
                                Rectangle {
                                    visible: cardDelegate.modelData.floating === true
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    height: 22
                                    width: floatLabel.implicitWidth + 16
                                    radius: 11
                                    color: "#8C000000"

                                    TritonText {
                                        id: floatLabel
                                        anchors.centerIn: parent
                                        text: "Floating"
                                        weight: TritonText.Weight.Medium
                                        font.pixelSize: 11
                                        color: Theme.onsurface
                                    }
                                }

                                // Attention dot.
                                Rectangle {
                                    visible: cardDelegate.modelData.attention === true
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Theme.tertiary
                                    border.width: 4
                                    border.color: "#4DFFB59B"
                                }
                            }

                            // App disc + title + workspace.
                            Row {
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: cardDelegate.isSelected ? Theme.primary : "#24FFFFFF"

                                    TritonIcon {
                                        anchors.centerIn: parent
                                        glyph: cardDelegate.modelData.glyph || Icons.terminal
                                        fill: true
                                        size: 18
                                        color: cardDelegate.isSelected ? Theme.onprimary : Theme.onsurface
                                    }
                                }

                                Column {
                                    spacing: 2

                                    TritonText {
                                        text: cardDelegate.modelData.title || ""
                                        weight: TritonText.Weight.SemiBold
                                        font.pixelSize: 13
                                        color: cardDelegate.isSelected ? Theme.onprimarycontainer : Theme.onsurface
                                        width: 130
                                        elide: Text.ElideRight
                                    }
                                    TritonText {
                                        text: cardDelegate.modelData.workspace || ""
                                        font.pixelSize: 12
                                        color: cardDelegate.isSelected ? Theme.onprimarycontainer : Theme.onsurface
                                        opacity: 0.75
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activated(index)
                    }
                }
            }
        }

        // Hints footer.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22

            Repeater {
                model: [
                    { key: "Tab", label: "next" },
                    { key: "⇧ Tab", label: "back" },
                    { key: "Q", label: "close" },
                    { key: "F", label: "float" },
                    { key: "Esc", label: "cancel" },
                ]

                Row {
                    id: hintRow
                    required property var modelData
                    property var hint: modelData
                    spacing: 8

                    Rectangle {
                        height: 24
                        width: Math.max(24, wKey.implicitWidth + 12)
                        radius: 7
                        color: "transparent"
                        border.width: 1
                        border.color: "#4DFFFFFF"

                        TritonText {
                            id: wKey
                            anchors.centerIn: parent
                            text: hintRow.hint.key
                            family: TritonText.Family.Mono
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            color: Theme.onsurface
                        }
                    }

                    TritonText {
                        text: hintRow.hint.label
                        font.pixelSize: 13
                        color: Theme.onsurfacevariant
                    }
                }
            }
        }
    }
}
