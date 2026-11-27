import QtQuick
import qs.foundations
import qs.tokens

// A titled run of SettingRows.
Column {
    id: root

    default property alias rows: list.data
    property string title: ""

    width: parent ? parent.width : implicitWidth
    spacing: Metrics.buttonGap

    AppText {
        visible: root.title !== ""
        role: "labelSmall"
        tone: "primary"
        text: root.title
    }
    Column {
        id: list
        width: parent.width
        spacing: Metrics.listGap
    }
}
