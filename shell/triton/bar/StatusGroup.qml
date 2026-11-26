pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "../components"
import ".."
import "../services"

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
    signal clicked

    implicitHeight: 44
    implicitWidth: row.implicitWidth + 36 // padding 18px each side (board .stat)
    radius: 22
    color: Theme.primaryContainer

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        propagateComposedEvents: true
        onClicked: mouse => {
            // Volume icon has its own handler; the rest of the pill opens QS.
            root.clicked();
            mouse.accepted = false;
        }
    }

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
                    visible: !SettingsService.get("shell", "batteryWavyRing", false)
                    glyph: root.batteryGlyph
                    size: 24
                    color: Theme.onprimarycontainer
                    anchors.verticalCenter: parent.verticalCenter
                }

                // The wave-ring battery: the shell's signature shape as the
                // charge gauge — store-gated alternative to the glyph.
                Item {
                    visible: SettingsService.get("shell", "batteryWavyRing", false)
                    width: 24
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    // Dim track ring, constant.
                    Shape {
                        anchors.fill: parent
                        antialiasing: true

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: "#40FFFFFF"
                            strokeWidth: 3
                            capStyle: ShapePath.RoundCap
                            scale: Qt.size(24 / 100, 24 / 100)
                            PathSvg { path: Theme.wavePath }
                        }
                    }
                    // Fill ring — the gauge level is translucency since QML
                    // Shapes can't stroke partial svg paths. Floor 25% so the
                    // ring never vanishes.
                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        opacity: Math.max(0.25, root.batteryPercent / 100)

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: root.batteryPercent <= 20 ? Theme.error : Theme.onprimarycontainer
                            strokeWidth: 3
                            capStyle: ShapePath.RoundCap
                            scale: Qt.size(24 / 100, 24 / 100)
                            PathSvg { path: Theme.wavePath }
                        }
                    }
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
