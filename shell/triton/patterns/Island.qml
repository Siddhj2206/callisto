import QtQuick
import qs.foundations
import qs.tokens

// A floating pill of bar content. Docked, it is just a row on the bar's strip.
// Its width springs when content appears or leaves.
Item {
    id: root

    default property alias content: row.data
    property bool docked: false
    property real startPad: docked ? 0 : Metrics.barPad
    property real endPad: docked ? 0 : Metrics.barPad

    implicitHeight: Metrics.barHeight
    implicitWidth: width_.value

    Spring {
        id: width_
        to: row.implicitWidth + root.startPad + root.endPad
        epsilon: 0.2
    }

    Material {
        anchors.fill: parent
        radius: height / 2
        kind: root.docked ? "none" : "glass"
    }

    Item {
        anchors.fill: parent
        clip: width_.running

        Row {
            id: row
            x: root.startPad
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.barGap
        }
    }
}
