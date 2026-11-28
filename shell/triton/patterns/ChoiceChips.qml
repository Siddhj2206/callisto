import QtQuick
import qs.primitives
import qs.tokens

// Pick one of many. `options` is [{ value, label }]. Wraps when given a width.
// A short, fixed set is a SegmentedButton.
Flow {
    id: root

    property var options: []
    property var current

    signal chosen(var value)

    spacing: Metrics.cardActions

    Repeater {
        model: root.options

        Chip {
            required property var modelData
            text: modelData.label
            selected: modelData.value === root.current
            onClicked: root.chosen(modelData.value)
        }
    }
}
