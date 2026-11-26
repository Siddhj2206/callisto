pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// Panel header: display title + supporting line, per the Settings board
// pattern (font 500 32-40px display at padding 28-36).

Column {
    id: root

    property string title: ""
    property string supporting: ""

    x: 32
    spacing: 4

    TritonText {
        text: root.title
        family: TritonText.Family.Display
        weight: TritonText.Weight.Medium
        font.pixelSize: 32
        color: Theme.onsurface
    }
    TritonText {
        visible: root.supporting !== ""
        text: root.supporting
        font.pixelSize: 14
        color: Theme.onsurfacevariant
    }
}
