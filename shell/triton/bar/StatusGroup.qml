pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import ".."

// The status group (BarStates `.stat`): a solid primary-container pill, 44px
// tall, radius 22, holding wifi + volume icons and the battery readout, all
// in on-primary-container. Leaf component: glyphs and percentage come in as
// properties; the container owns the services.
//
// Board CSS: height 44, radius 22, padding 0 18, gap 16. Battery icon and
// percentage are 6px apart (board markup). No battery means the readout is
// absent entirely — never a placeholder. Volume is interactive: scroll
// adjusts, click toggles mute.

Rectangle {
    id: root

    required property string wifiGlyph
    required property string volumeGlyph
    required property string batteryGlyph
    required property int batteryPercent

    signal volumeScrolled(real delta)
    signal volumeClicked

    implicitHeight: 44
    implicitWidth: row.implicitWidth + 36 // padding 18px each side (board .stat)
    radius: 22
    color: Theme.primaryContainer

    ContentRow {
        id: row
        spacing: 16 // board .stat gap

        TritonIcon {
            visible: root.wifiGlyph !== ""
            glyph: root.wifiGlyph
            size: 24
            color: Theme.onprimarycontainer
        }

        TritonIcon {
            visible: root.volumeGlyph !== ""
            glyph: root.volumeGlyph
            size: 24
            color: Theme.onprimarycontainer

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.volumeClicked()
                onWheel: wheel => {
                    // 120 is one wheel notch; 5% per notch.
                    const steps = wheel.angleDelta.y / 120;
                    if (steps !== 0)
                        root.volumeScrolled(steps * 0.05);
                }
            }
        }

        // Battery cluster: icon + percentage, 6px apart per the board markup.
        Item {
            visible: root.batteryGlyph !== ""
            implicitWidth: batteryRow.implicitWidth
            implicitHeight: 24

            Row {
                id: batteryRow
                spacing: 6
                height: parent.height

                TritonIcon {
                    glyph: root.batteryGlyph
                    size: 24
                    color: Theme.onprimarycontainer
                    anchors.verticalCenter: parent.verticalCenter
                }

                TritonText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryPercent + "%"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 14
                    color: Theme.onprimarycontainer
                }
            }
        }
    }
}
