import QtQuick
import qs
import qs.foundations
import qs.tokens

// On/off. The thumb grows and crosses over, gaining a check.
Pressable {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    readonly property Scheme scheme: Theming.of(root)

    implicitWidth: Metrics.switchWidth
    implicitHeight: Metrics.switchHeight
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    fill: checked ? scheme.primary : scheme.surfaceContainerHighest
    ink: scheme.onsurface
    onClicked: toggled(!checked)

    Spring {
        id: travel
        to: root.checked ? 1 : 0
        token: Motion.spatialFast
        epsilon: 0.001
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: Metrics.switchBorder
        border.color: root.checked ? root.scheme.primary : root.scheme.outline
        Behavior on border.color { ColorFade {} }
    }

    Rectangle {
        readonly property real size: Metrics.switchThumbOff + (Metrics.switchThumbOn - Metrics.switchThumbOff) * travel.value

        width: size
        height: size
        radius: size / 2
        x: root.height / 2 - size / 2 + (root.width - root.height) * travel.value
        y: root.height / 2 - size / 2
        color: root.checked ? root.scheme.onprimary : root.scheme.outline
        Behavior on color { ColorFade {} }

        Icon {
            visible: root.checked
            anchors.centerIn: parent
            glyph: Icons.check
            size: "sm"
            tone: "primary"
        }
    }
}
