pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The power menu (Power board): full-screen over blurred wallpaper with a
// blue-black veil. Greeting at top 270, connected 5-segment group centered,
// unsaved warning pill, keyboard hints, mono footer.
//
// Focus is a segment index; the focused shutdown expands into the wide
// tertiary pill (focused action grows and gains its label — the board's one
// morph). In practice shutdown is the default focus target for Enter, while
// Lock is the safest-first position per PowerStates.

Item {
    id: root

    property string greeting: "Good evening"
    property string userName: ""
    property string uptimeText: ""
    // -1 none; otherwise 0..4 = lock/sleep/logout/restart/shutdown
    property int focusIndex: 4
    property string unsavedText: ""
    property string footerText: "callisto · triton"

    signal actionTriggered(int idx)
    signal cancel()

    // Segments: icon, label, fill color, content color.
    readonly property var segments: [
        { icon: Icons.lock, label: "Lock", bg: Theme.primaryContainer, fg: Theme.onprimarycontainer, fillIcon: false },
        { icon: Icons.bedtime, label: "Sleep", bg: Theme.secondaryContainer, fg: Theme.onsecondarycontainer, fillIcon: false },
        { icon: Icons.logout, label: "Log out", bg: Theme.secondaryContainer, fg: Theme.onsecondarycontainer, fillIcon: false },
        { icon: Icons.restartAlt, label: "Restart", bg: Theme.tertiaryContainer, fg: Theme.ontertiarycontainer, fillIcon: false },
        { icon: Icons.powerSettingsNew, label: "Shut down", bg: Theme.tertiary, fg: Theme.ontertiary, fillIcon: true },
    ]

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            focusIndex = Math.max(0, focusIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            focusIndex = Math.min(4, focusIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            actionTriggered(focusIndex);
            event.accepted = true;
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
            actionTriggered(event.key - Qt.Key_1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            cancel();
            event.accepted = true;
        }
    }

    // Greeting.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.25)
        spacing: 12

        TritonText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.greeting + (root.userName ? ", " + root.userName : "")
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 64
            font.letterSpacing: -1.2
            color: Theme.onsurface
        }
        TritonText {
            visible: root.uptimeText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.uptimeText
            font.pixelSize: 17
            color: Theme.onsurface
            opacity: 0.85
        }
    }

    // Connected group.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.39)
        spacing: 6

        Repeater {
            model: 5

            delegate: Item {
                id: segRoot
                required property int index
                property var seg: root.segments[index]
                property bool focused: root.focusIndex === index

                width: focused && index === 4 ? 300 : 140
                height: 140

                Behavior on width { NumberAnimation { duration: 150 } }

                RoundedRect {
                    anchors.fill: parent
                    radii: index === 0 ? [70, 14, 14, 70]
                         : index === 4 ? [70, 70, 70, 70]
                         : [14, 14, 14, 14]
                    color: parent.seg.bg
                }

                // Resting: icon over label, centered column.
                Column {
                    visible: !(segRoot.focused && segRoot.index === 4)
                    anchors.centerIn: parent
                    spacing: 10

                    TritonIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        glyph: segRoot.seg.icon
                        fill: segRoot.seg.fillIcon
                        size: 44
                        color: segRoot.seg.fg
                    }
                    TritonText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: segRoot.seg.label
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 15
                        color: segRoot.seg.fg
                    }
                }

                // Focused shutdown: horizontal pill content.
                Row {
                    visible: segRoot.focused && segRoot.index === 4
                    anchors.centerIn: parent
                    spacing: 16

                    TritonIcon {
                        glyph: segRoot.seg.icon
                        fill: true
                        size: 52
                        color: segRoot.seg.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        TritonText {
                            text: segRoot.seg.label
                            family: TritonText.Family.Display
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 32
                            font.letterSpacing: -0.3
                            color: segRoot.seg.fg
                        }
                        TritonText {
                            text: "Press Enter"
                            weight: TritonText.Weight.Medium
                            font.pixelSize: 13
                            color: segRoot.seg.fg
                            opacity: 0.8
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actionTriggered(index)
                }
            }
        }
    }

    // Unsaved warning pill.
    Rectangle {
        visible: root.unsavedText !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.56)
        height: 48
        width: warnRow.implicitWidth + 36
        radius: 24
        color: Theme.glassBg

        Row {
            id: warnRow
            anchors.centerIn: parent
            spacing: 10

            TritonIcon {
                glyph: Icons.warning
                fill: true
                size: 24
                color: Theme.tertiary
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: root.unsavedText
                weight: TritonText.Weight.Medium
                font.pixelSize: 15
                color: Theme.onsurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Hints.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.64)
        spacing: 26

        Repeater {
            model: [
                { keys: ["←", "→"], label: "move" },
                { keys: ["Enter"], label: "confirm" },
                { keys: ["1", "–", "5"], label: "jump" },
                { keys: ["Esc"], label: "cancel" },
            ]

            Row {
                required property var modelData
                spacing: 8

                Repeater {
                    model: parent.modelData.keys

                    delegate: Item {
                        required property string modelData
                        width: modelData === "–" ? dashText.implicitWidth : Math.max(24, hintKey.implicitWidth + 12)
                        height: 24

                        Rectangle {
                            visible: parent.modelData !== "–"
                            anchors.fill: parent
                            radius: 7
                            color: "transparent"
                            border.width: 1
                            border.color: "#4DFFFFFF"
                        }

                        TritonText {
                            id: hintKey
                            visible: parent.modelData !== "–"
                            anchors.centerIn: parent
                            text: parent.modelData
                            family: TritonText.Family.Mono
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            color: Theme.onsurface
                        }
                        TritonText {
                            id: dashText
                            visible: parent.modelData === "–"
                            anchors.centerIn: parent
                            text: "–"
                            font.pixelSize: 12
                            color: Theme.onsurfacevariant
                        }
                    }
                }

                TritonText {
                    text: parent.modelData.label
                    font.pixelSize: 13
                    color: Theme.onsurfacevariant
                }
            }
        }
    }

    // Footer.
    TritonText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        text: root.footerText
        family: TritonText.Family.Mono
        font.pixelSize: 12
        color: Theme.onsurfacevariant
    }
}
