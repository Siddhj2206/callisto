import QtQuick
import qs.tokens

// The only way to draw text. `role` picks the type style, `tone` a color role.
// The bundled fonts are static instances, so weight is part of the family name.
Text {
    id: root

    property string role: "body"
    property string tone: "onsurface"
    property int weight: 0 // 0 = the role's weight
    property bool tabular: false

    readonly property var spec: Typography.roles[role]
    readonly property int effectiveWeight: weight > 0 ? weight : spec.weight

    font.family: spec.family + (effectiveWeight >= 600 ? " SemiBold" : effectiveWeight >= 500 ? " Medium" : "")
    font.pixelSize: spec.size
    font.features: tabular ? ({ "tnum": 1 }) : ({})
    lineHeightMode: Text.FixedHeight
    lineHeight: spec.line
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    color: Theming.of(root)[tone]
}
