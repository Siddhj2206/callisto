import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// One result. While `choosing`, the row's actions replace its subtitle.
Pressable {
    id: root

    required property var row
    property bool selected: false
    property bool choosing: false
    property int action: 0

    signal actionTriggered(string id)

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: selected ? "onsecondarycontainer" : "onsurface"

    implicitHeight: Metrics.resultRow
    radius: Metrics.listCardRadius
    fill: selected ? scheme.secondaryContainer : "transparent"
    ink: scheme[tone]
    label: row.title

    Avatar {
        id: disc
        x: Metrics.cardActions
        anchors.verticalCenter: parent.verticalCenter
        source: root.row.icon
        glyph: root.row.glyph
        tone: root.tone
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: disc.right
        anchors.leftMargin: Metrics.rowGap
        anchors.right: hint.left
        anchors.rightMargin: Metrics.rowGap

        AppText {
            width: parent.width
            role: "label"
            tone: root.tone
            textFormat: Text.PlainText
            text: root.row.title
        }
        AppText {
            width: parent.width
            visible: !root.choosing && text !== ""
            role: "bodySmall"
            tone: root.selected ? root.tone : "onsurfacevariant"
            textFormat: Text.PlainText
            text: root.row.subtitle
        }
        Row {
            visible: root.choosing
            spacing: Metrics.cardActions

            Repeater {
                model: root.choosing ? root.row.actions : []

                Button {
                    required property var modelData
                    required property int index
                    height: Metrics.keycap
                    text: modelData.label
                    variant: index === root.action ? "filled" : "veil"
                    activeFocusOnTab: false
                    onClicked: root.actionTriggered(modelData.id)
                }
            }
        }
    }

    Keycap {
        id: hint
        anchors.right: parent.right
        anchors.rightMargin: Metrics.rowPad
        anchors.verticalCenter: parent.verticalCenter
        visible: root.selected && !root.choosing
        text: "Enter"
    }
}
