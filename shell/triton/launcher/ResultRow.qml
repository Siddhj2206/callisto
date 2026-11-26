pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import ".."
import "../components"

// A launcher result row (Launcher board `.r`): 56px tall, radius 20, padding
// 8px left / 12px right, 14px gaps. Apps, files and windows carry a 40px
// circular icon disc (`.t-ic`, tint varies per result); command results use
// a bare icon with 6px left margin instead — pass useDisc: false.
//
// Selected state fills the row in secondary-container and re-tints all text
// to the on-color.

Rectangle {
    id: root

    property string glyph: ""
    property string iconName: "" // themed icon name — wins over glyph when set
    property bool fillGlyph: false
    property string title: ""
    property string subtitle: ""
    property string tag: ""
    // Trailing key hint (selected command rows show "Enter").
    property string keyHint: ""
    property bool selected: false
    // Disc colors — the board tints per result kind (tertiary-container,
    // secondary-container, primary-container, highest). Caller picks.
    property color discColor: Theme.secondaryContainer
    property color discContentColor: Theme.onsecondarycontainer
    property bool useDisc: true

    signal clicked

    width: parent ? parent.width : 400
    height: 56
    radius: 20
    color: root.selected ? Theme.secondaryContainer : "transparent"

    readonly property color contentColor: root.selected ? Theme.onsecondarycontainer : Theme.onsurface
    readonly property color subtitleColor: root.selected ? Theme.onsecondarycontainer : Theme.onsurfacevariant

    Row {
        x: 8
        height: parent.height
        spacing: 14

        // Icon: 40px disc for apps/files/windows, bare glyph for commands.
        Item {
            width: root.useDisc ? 40 : 24 + 6 // board: bare icons get margin-left:6
            height: parent.height

            Rectangle {
                visible: root.useDisc
                width: 40
                height: 40
                anchors.centerIn: parent
                radius: 20
                color: root.discColor

                TritonIcon {
                    visible: root.iconName === ""
                    anchors.centerIn: parent
                    glyph: root.glyph
                    fill: root.fillGlyph
                    size: 22
                    color: root.discContentColor
                }

                IconImage {
                    visible: root.iconName !== ""
                    anchors.centerIn: parent
                    implicitSize: 24
                    asynchronous: true
                    source: root.iconName !== "" ? Quickshell.iconPath(root.iconName, "application-x-executable") : ""
                }
            }

            TritonIcon {
                visible: !root.useDisc
                anchors.centerIn: parent
                glyph: root.glyph
                fill: root.fillGlyph
                size: 24
                color: root.selected ? root.contentColor : Theme.onsurfacevariant
            }
        }

        // Title over subtitle, vertically centered as a pair.
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            TritonText {
                text: root.title
                weight: TritonText.Weight.Medium
                font.pixelSize: 16
                color: root.contentColor
            }
            TritonText {
                visible: root.subtitle !== ""
                text: root.subtitle
                font.pixelSize: 13
                color: root.subtitleColor
            }
        }
    }

    // Trailing: workspace tag (`.e`) or keyboard hint, right-aligned at 12px.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            visible: root.keyHint !== ""
            height: 24
            width: Math.max(24, hintText.implicitWidth + 12)
            radius: 7
            color: "transparent"
            border.width: 1
            border.color: "#4DFFFFFF"

            TritonText {
                id: hintText
                anchors.centerIn: parent
                text: root.keyHint
                family: TritonText.Family.Mono
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 12
                color: root.contentColor
            }
        }

        Rectangle {
            visible: root.tag !== ""
            height: tagLabel.implicitHeight + 6
            width: tagLabel.implicitWidth + 16
            radius: 10
            color: Theme.secondaryContainer

            TritonText {
                id: tagLabel
                anchors.centerIn: parent
                text: root.tag
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 12
                color: Theme.onsecondarycontainer
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
