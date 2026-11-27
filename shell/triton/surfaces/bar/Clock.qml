import QtQuick
import qs.foundations
import qs.tokens

// Time and date sharing one baseline.
Item {
    id: root

    property string time: ""
    property string date: ""

    implicitWidth: Metrics.clockStart + timeText.width + Metrics.clockGap + dateText.width + Metrics.clockEnd
    implicitHeight: Metrics.barSlot

    AppText {
        id: timeText
        x: Metrics.clockStart
        anchors.verticalCenter: parent.verticalCenter
        role: "clock"
        tabular: true
        text: root.time
    }
    AppText {
        id: dateText
        anchors.left: timeText.right
        anchors.leftMargin: Metrics.clockGap
        anchors.baseline: timeText.baseline
        role: "date"
        tone: "onsurfacevariant"
        text: root.date
    }
}
