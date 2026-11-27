import QtQuick
import qs.foundations
import qs.tokens

// A filter or mode tag: outlined, filled when selected.
Pressable {
    id: root

    property string text: ""
    property bool selected: false

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: selected ? "onsecondarycontainer" : "onsurface"

    label: text
    implicitHeight: Metrics.chipHeight
    implicitWidth: caption.implicitWidth + Metrics.buttonPad * 2
    radius: Metrics.pressRadius
    ink: scheme[tone]
    fill: selected ? scheme.secondaryContainer : "transparent"

    Rectangle {
        visible: !root.selected
        anchors.fill: parent
        radius: root.shapeRadius
        color: "transparent"
        border.width: 1
        border.color: root.scheme.outlineVariant
    }
    AppText {
        id: caption
        anchors.centerIn: parent
        role: "label"
        tone: root.tone
        text: root.text
    }
}
