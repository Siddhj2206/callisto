import QtQuick
import qs.tokens

// A surface material. Blur comes from the compositor's layer rule; this draws
// the translucent fill and, for floating materials, the lit top edge.
Rectangle {
    id: root

    property string kind: "glass" // "glass" | "thick" | "mica" | "none"
    readonly property Scheme scheme: Theming.of(root)

    color: kind === "glass" ? scheme.glass : kind === "thick" ? scheme.thick
         : kind === "mica" ? scheme.mica : "transparent"
    Behavior on color { ColorFade {} }

    Rectangle {
        visible: root.kind === "glass" || root.kind === "thick"
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(root.scheme.highlight, root.scheme.highlight.a / 2)
    }
}
