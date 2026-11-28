pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.tokens

// A connected group: pick one of a few. `options` is [{ value, label, glyph }],
// the glyph optional. The segments are equally wide and share whatever width the
// group is given; the ends are round, the seams nearly square, and the selected
// one rounds off completely. For longer lists, use ChoiceChips.
Item {
    id: root

    property var options: []
    property var current
    property bool large: false
    property bool takesFocus: true

    signal chosen(var value)

    readonly property Scheme scheme: Theming.of(root)
    readonly property real gaps: Metrics.segmentGap * Math.max(0, options.length - 1)
    readonly property real cell: options.length > 0 ? (width - gaps) / options.length : 0
    property real widest: 0 // the most any label needs

    implicitWidth: widest * options.length + gaps
    implicitHeight: large ? Metrics.buttonHeight : Metrics.control

    Repeater {
        model: root.options

        Pressable {
            id: segment
            required property var modelData
            required property int index
            readonly property bool selected: modelData.value === root.current
            readonly property string tone: selected ? "onprimary" : "onsurface"
            readonly property real natural: face.implicitWidth + Metrics.buttonPad * 2

            onNaturalChanged: root.widest = Math.max(root.widest, natural)
            Component.onCompleted: root.widest = Math.max(root.widest, natural)

            x: index * (root.cell + Metrics.segmentGap)
            width: root.cell
            height: root.height
            radius: selected || index === 0 ? height / 2 : Metrics.segmentInner
            radiusRight: selected || index === root.options.length - 1 ? height / 2 : Metrics.segmentInner
            fill: selected ? root.scheme.primary : root.scheme.veil
            ink: root.scheme[tone]
            label: modelData.label
            activeFocusOnTab: root.takesFocus
            Accessible.role: Accessible.RadioButton
            Accessible.checked: selected
            onClicked: root.chosen(modelData.value)

            Row {
                id: face
                anchors.centerIn: parent
                spacing: Metrics.buttonGap

                Icon {
                    visible: (segment.modelData.glyph ?? "") !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: segment.modelData.glyph ?? ""
                    fill: segment.selected
                    tone: segment.tone
                }
                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "label"
                    tone: segment.tone
                    text: segment.modelData.label
                }
            }
        }
    }
}
