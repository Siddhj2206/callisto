import QtQuick
import qs.foundations
import qs.tokens

// Network and battery on the lock and login screens. Hidden when there is
// nothing to say.
Material {
    id: root

    property string networkGlyph: ""
    property string batteryGlyph: ""
    property int batteryPercent: -1 // -1: no battery

    visible: networkGlyph !== "" || batteryPercent >= 0
    implicitWidth: status.width + Metrics.buttonPad * 2
    implicitHeight: Metrics.buttonHeight
    radius: height / 2

    Row {
        id: status
        anchors.centerIn: parent
        spacing: Metrics.statusGap

        Icon {
            visible: root.networkGlyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.networkGlyph
        }
        Row {
            visible: root.batteryPercent >= 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.batteryGap

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                glyph: root.batteryGlyph
            }
            AppText {
                anchors.verticalCenter: parent.verticalCenter
                role: "label"
                text: root.batteryPercent + "%"
            }
        }
    }
}
