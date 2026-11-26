pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "../components"
import ".."

// The clock (BarStates `.clk`): Jost 26px semibold time, Google Sans Flex
// 14px medium date in on-surface-variant. The board aligns them on their
// BASELINE (`.clk{display:flex;align-items:baseline;gap:12px;padding:0 16px
// 0 18px}`).
//
// Baseline alignment in QML: Text exposes `baselineOffset` — the distance
// from the item's top to the baseline. Sharing one baseline target therefore
// means: child.y = baseline - child.baselineOffset. The baseline itself is
// chosen so the digit cap height (no descenders in HH:mm) centers optically
// in the island: capHeight ≈ 0.72 × 26px for Jost, so the baseline sits at
// center + capHeight/2.

Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    implicitWidth: timeText.width + 12 + dateText.width + 18 + 16 // board .clk padding
    implicitHeight: Theme.barHeight

    readonly property real capHeight: 26 * 0.72 // Jost digits, no descenders
    readonly property real baselineY: height / 2 + capHeight / 2

    TritonText {
        id: timeText
        y: root.baselineY - baselineOffset
        x: 18
        text: Qt.formatDateTime(clock.date, "HH:mm")
        family: TritonText.Family.Display
        weight: TritonText.Weight.SemiBold
        font.pixelSize: 26
        color: Theme.onsurface
    }

    TritonText {
        id: dateText
        y: root.baselineY - baselineOffset
        x: 18 + timeText.width + 12
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        weight: TritonText.Weight.Medium
        font.pixelSize: 14
        color: Theme.onsurfacevariant
    }
}
