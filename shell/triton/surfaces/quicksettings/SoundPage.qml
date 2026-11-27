pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.primitives

// Output devices; the picked one becomes the default.
ListPage {
    id: root

    property var outputs: [] // [{ node, name }]
    property var current: null

    signal outputClicked(var node)

    title: "Sound"
    empty: outputs.length === 0
    emptyText: "No output devices"
    settingsText: "All sound settings"

    Repeater {
        model: root.outputs

        ListRow {
            required property var modelData
            required property int index

            width: parent.width
            first: index === 0
            last: index === root.outputs.length - 1
            glyph: /head/i.test(modelData.name) ? Icons.headphones : Icons.speaker
            title: modelData.name
            selected: modelData.node === root.current
            trailingGlyph: selected ? Icons.checkCircle : ""
            onClicked: root.outputClicked(modelData.node)
        }
    }
}
