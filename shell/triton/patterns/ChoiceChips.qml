import QtQuick
import qs.primitives
import qs.tokens

// Pick one of a few. `options` is [{ value, label }]. Wraps when given a width.
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
