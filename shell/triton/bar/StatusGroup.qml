pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The status group (BarStates `.stat`): a solid primary-container pill, 44px
// tall, radius 22, holding wifi + volume icons and the battery readout, all
// in on-primary-container. Leaf component: icons and percentage come in as
// properties; the container owns Pipewire/UPower.
//
// Board CSS: height 44, radius 22, padding 0 18, gap 16, font-weight 600.
// Battery icon and percentage are 6px apart (board markup). When there is no
// battery, the battery row is empty and collapses — no placeholder garbage.
// Volume is interactive: scroll adjusts, click toggles mute.

Rectangle {
    id: root

    required property string wifiIcon
    required property string volumeIcon
    required property string batteryIcon
    required property int batteryPercent

    signal volumeScrolled(real delta)
    signal volumeClicked

    implicitHeight: 44
    implicitWidth: row.implicitWidth + 36 // padding 18px each side (board .stat)
    radius: 22
    color: Theme.primaryContainer

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16 // board .stat gap

        Text {
            visible: root.wifiIcon !== ""
            text: root.wifiIcon
            color: Theme.onprimarycontainer
            font.family: "Triton Symbols"
            font.pixelSize: 24
        }

        Text {
            id: volumeGlyph
            visible: root.volumeIcon !== ""
            text: root.volumeIcon
            color: Theme.onprimarycontainer
            font.family: "Triton Symbols"
            font.pixelSize: 24

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.volumeClicked()
                onWheel: wheel => {
                    // Board-adjacent behavior: scroll the volume icon to
                    // adjust. 120 is one wheel notch; 5% per notch.
                    const steps = wheel.angleDelta.y / 120;
                    if (steps !== 0)
                        root.volumeScrolled(steps * 0.05);
                }
            }
        }

        Row {
            visible: root.batteryIcon !== ""
            spacing: 6 // board markup: battery icon/text gap
            height: parent.height

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryIcon
                color: Theme.onprimarycontainer
                font.family: "Triton Symbols"
                font.pixelSize: 24
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryPercent + "%"
                color: Theme.onprimarycontainer
                font.family: "Google Sans Flex"
                font.weight: Font.DemiBold
                font.pixelSize: 14
            }
        }
    }
}
