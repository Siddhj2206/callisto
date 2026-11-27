import QtQuick
import qs.foundations
import qs.tokens

// A page in the sidebar.
Pressable {
    id: root

    property string glyph: ""
    property string title: ""
    property bool selected: false

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: selected ? "onsecondarycontainer" : "onsurface"

    width: parent ? parent.width : implicitWidth
    implicitHeight: Metrics.control
    label: title
    fill: selected ? scheme.secondaryContainer : "transparent"
    ink: scheme[tone]

    Icon {
        id: leading
        x: Metrics.rowPad
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.glyph
        size: "lg"
        fill: root.selected
        tone: root.tone
    }
    AppText {
        anchors.left: leading.right
        anchors.leftMargin: Metrics.rowGap
        anchors.right: parent.right
        anchors.rightMargin: Metrics.rowPad
        anchors.verticalCenter: parent.verticalCenter
        role: "label"
        tone: root.tone
        text: root.title
    }
}
