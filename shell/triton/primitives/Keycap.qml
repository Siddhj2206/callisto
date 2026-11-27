import QtQuick
import qs.foundations
import qs.tokens

// A keyboard key, as drawn in hints.
Rectangle {
    id: root

    property string text: ""
    readonly property Scheme scheme: Theming.of(root)

    implicitHeight: Metrics.keycap
    implicitWidth: Math.max(Metrics.keycap, caption.implicitWidth + Metrics.cardActions)
    radius: Metrics.listCardTail
    color: "transparent"
    border.width: 1
    border.color: scheme.outlineVariant

    AppText {
        id: caption
        anchors.centerIn: parent
        role: "labelSmall"
        tone: "onsurfacevariant"
        text: root.text
    }
}
