pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The notification center (Notifications board): Glass panel w440 r28,
// padding 18/16, right-anchored full height minus 20px margins. Header row
// (Jost 30 title + DND tonal pill), then groups: header row with 32px app
// disc, name, count, expand chevron, Clear — then `.pn` items, collapsed
// groups rendering as one card with a 12px-inset peek behind it.

Rectangle {
    id: root

    // Group model: [{ app, glyph, fillGlyph?, discColor?, discContentColor?,
    //   count, expanded, items: [{title, preview, time}], clearable }]
    property var groups: []
    property bool dndActive: false

    signal clearGroup(int idx)
    signal toggleGroup(int idx)
    signal dndToggled

    width: 440
    radius: 28
    color: Theme.glassBg
    implicitHeight: centerCol.implicitHeight + 36
    clip: true

    Column {
        id: centerCol
        x: 16
        y: 18
        width: parent.width - 32
        spacing: 0

        // Header: title + DND pill.
        Item {
            width: parent.width
            height: 40

            TritonText {
                text: "Notifications"
                family: TritonText.Family.Display
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 30
                font.letterSpacing: -0.4
                color: Theme.onsurface
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                width: dndRow.implicitWidth + 24
                radius: 18
                color: Theme.secondaryContainer

                Row {
                    id: dndRow
                    anchors.centerIn: parent
                    spacing: 6

                    TritonIcon {
                        glyph: Icons.darkMode
                        size: 18
                        color: Theme.onsecondarycontainer
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonText {
                        text: "DND"
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 13
                        color: Theme.onsecondarycontainer
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dndToggled()
                }
            }
        }

        Item { width: 1; height: 4 }

        // Groups — inside a bounded Flickable: without scrolling the window
        // clips away everything past the first screenful.
        Flickable {
            width: parent.width
            height: Math.min(groupsCol.implicitHeight, 520)
            contentWidth: width
            contentHeight: groupsCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groupsCol
                width: parent.width

                Repeater {
                    model: root.groups

            delegate: Column {
                required property var modelData
                required property int index
                property var grp: modelData
                property int grpIndex: index

                width: parent.width
                spacing: 6

                // Group header row.
                Item {
                    width: parent.width
                    height: 48 // padding 10/6/8 around the 32px disc

                    Row {
                        x: 6
                        height: parent.height
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: grp.discColor || Theme.surfaceContainerHighest

                            TritonIcon {
                                anchors.centerIn: parent
                                glyph: grp.glyph || ""
                                fill: grp.fillGlyph || false
                                size: 20
                                color: grp.discContentColor || Theme.onsurfacevariant
                            }
                        }

                        TritonText {
                            text: grp.app || ""
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 15
                            color: Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TritonText {
                            visible: (grp.count || 0) > 0
                            text: grp.countText || String(grp.count)
                            font.pixelSize: 12
                            color: Theme.onsurfacevariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        height: parent.height
                        spacing: 12

                        TritonIcon {
                            glyph: grp.expanded ? Icons.expandLess : Icons.expandMore
                            size: 20
                            color: Theme.onsurfacevariant
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleGroup(grpIndex)
                            }
                        }

                        TritonText {
                            visible: grp.clearable === true
                            text: "Clear"
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 13
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearGroup(grpIndex)
                            }
                        }
                    }
                }

                // Items: expanded rows, or the collapsed stack with peek.
                Column {
                    width: parent.width
                    spacing: 6
                    visible: grp.expanded

                    Repeater {
                        model: grp.items || []

                        delegate: Item {
                            required property var modelData
                            width: parent.width
                            height: pnCol.implicitHeight + 24

                            RoundedRect {
                                anchors.fill: parent
                                radii: [20, 20, 20, 8]
                                color: Theme.veilLow // white .09
                            }

                            Column {
                                id: pnCol
                                x: 14
                                y: 12
                                width: parent.width - 28 - timeLabel.implicitWidth - 12
                                spacing: 2

                                TritonText {
                                    text: modelData.title || ""
                                    weight: TritonText.Weight.SemiBold
                                    font.pixelSize: 15
                                    color: Theme.onsurface
                                }
                                TritonText {
                                    text: modelData.preview || ""
                                    font.pixelSize: 13
                                    color: Theme.onsurfacevariant
                                }
                            }

                            TritonText {
                                id: timeLabel
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                y: 12
                                text: modelData.time || ""
                                font.pixelSize: 12
                                color: Theme.onsurfacevariant
                            }
                        }
                    }

                    TritonText {
                        visible: (grp.hiddenCount || 0) > 0
                        text: "Show " + grp.hiddenCount + " more"
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 13
                        color: Theme.primary
                        leftPadding: 8
                        topPadding: 2
                        bottomPadding: 2
                    }
                }

                // Collapsed stack: one card with a 12px-inset 50%-opacity peek.
                Item {
                    visible: !grp.expanded && (grp.items || []).length > 0
                    width: parent.width
                    height: 62

                    RoundedRect {
                        visible: (grp.items || []).length > 1
                        x: 12
                        y: 10
                        width: parent.width - 24
                        height: 50
                        opacity: 0.5
                        radii: [20, 20, 20, 8]
                        color: Theme.veilLow
                    }

                    Item {
                        width: parent.width
                        height: collapsedCol.implicitHeight + 24

                        RoundedRect {
                            anchors.fill: parent
                            radii: [20, 20, 20, 8]
                            color: Theme.veilLow
                        }

                        Column {
                            id: collapsedCol
                            x: 14
                            y: 12
                            width: parent.width - 28 - collapsedTime.implicitWidth - 12
                            spacing: 2

                            TritonText {
                                text: (grp.items && grp.items[0]) ? grp.items[0].title || "" : ""
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 15
                                color: Theme.onsurface
                            }
                            TritonText {
                                text: (grp.items && grp.items[0]) ? grp.items[0].preview || "" : ""
                                font.pixelSize: 13
                                color: Theme.onsurfacevariant
                            }
                        }

                        TritonText {
                            id: collapsedTime
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            y: 12
                            text: (grp.items && grp.items[0]) ? grp.items[0].time || "" : ""
                            font.pixelSize: 12
                            color: Theme.onsurfacevariant
                        }
                    }
                }
            }
        }
            }
        }
    }
}
