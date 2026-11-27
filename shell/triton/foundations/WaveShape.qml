import QtQuick
import QtQuick.Shapes
import qs.tokens

// The nine-lobe Triton wave, for identity elements only. Fill it, stroke it,
// and put content on top.
Item {
    id: root

    default property alias content: holder.data
    property color color: Theming.of(root).primary
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            scale: Qt.size(root.width / 100, root.height / 100)
            PathSvg { path: Metrics.wavePath }
        }
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}
