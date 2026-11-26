pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import ".."

// The clock (BarStates `.clk`): big time in Jost 26px semibold beside the
// smaller date ("Sat 21 Nov") in on-surface-variant. Board padding is
// 0 16px 0 18px — 16/18px are off the spacing scale, derived from
// `.clk{padding:0 16px 0 18px}`.
//
// SystemClock drives the text; no `new Date()` in bindings.

Item {
    id: root

    implicitWidth: row.implicitWidth + 18 + 16
    implicitHeight: Theme.barHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12 // board: .clk gap 12px

        Text {
            anchors.baseline: dateText.baseline
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.onsurface
            font.family: "Jost SemiBold"
            font.pixelSize: 26
        }

        Text {
            id: dateText
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Theme.onsurfacevariant
            font.family: "Google Sans Flex"
            font.weight: Font.Medium
            font.pixelSize: 14
        }
    }
}
