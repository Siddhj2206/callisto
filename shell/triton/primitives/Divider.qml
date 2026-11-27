import QtQuick
import qs.foundations
import qs.tokens

Rectangle {
    id: root
    property bool horizontal: false
    implicitWidth: horizontal ? 0 : 1
    implicitHeight: horizontal ? 1 : Metrics.dividerHeight
    color: Theming.of(root).veilHi
}
