import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// Focused app and document, shown at the end of the left island.
Row {
    id: root

    property string appName: ""
    property string title: ""

    spacing: Metrics.titleGap

    Item {
        width: Metrics.titlePad
        height: 1
    }
    Divider {
        anchors.verticalCenter: parent.verticalCenter
    }
    Item {
        width: Metrics.barGap
        height: 1
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.webAsset
        fill: true
        tone: "primary"
    }
    AppText {
        anchors.verticalCenter: parent.verticalCenter
        role: "label"
        text: root.appName
    }
    AppText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.title !== "" && root.title.toLowerCase() !== root.appName.toLowerCase()
        width: Math.min(implicitWidth, Metrics.titleMax)
        role: "bodySmall"
        tone: "onsurfacevariant"
        text: root.title
    }
    Item {
        width: Metrics.titlePad
        height: 1
    }
}
