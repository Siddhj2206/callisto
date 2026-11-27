import QtQuick
import qs.foundations
import qs.tokens

// A round button holding one icon. Selected buttons go from circle to rounded
// square and take color.
Pressable {
    id: root

    property string glyph: ""
    property string variant: "standard" // "standard" | "veil" | "filled" | "tonal"
    property bool selected: false
    property string iconSize: "md"
    property real size: Metrics.barSlot

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: variant === "filled" ? "onprimary"
        : variant === "tonal" || selected ? "onsecondarycontainer" : "onsurface"

    implicitWidth: size
    implicitHeight: size
    radius: selected ? Metrics.pressRadius : size / 2
    ink: scheme[tone]
    fill: variant === "filled" ? scheme.primary
        : variant === "tonal" || selected ? scheme.secondaryContainer
        : variant === "veil" ? scheme.veil : "transparent"

    Icon {
        anchors.centerIn: parent
        glyph: root.glyph
        size: root.iconSize
        fill: root.selected || root.variant === "filled"
        tone: root.tone
    }
}
