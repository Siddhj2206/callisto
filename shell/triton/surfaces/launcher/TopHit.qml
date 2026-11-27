import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// The best match, large, with its two likeliest actions. While `choosing`, all
// of them are listed in place of the description.
Pressable {
    id: root

    required property var row
    property bool selected: false
    property bool choosing: false
    property int action: 0

    signal actionTriggered(string id)

    readonly property Scheme scheme: Theming.of(root)

    radius: Metrics.radiusPanelS
    fill: scheme.primaryContainer
    ink: scheme.onprimarycontainer
    label: "Top hit: " + row.title

    Column {
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardGap

        AppText {
            role: "labelSmall"
            tone: "onprimarycontainer"
            text: "TOP HIT"
        }
        Avatar {
            size: Metrics.topHitDisc
            iconSize: Metrics.topHitDisc / 2
            source: root.row.icon
            glyph: root.row.glyph
        }
        AppText {
            width: parent.width
            role: "headline"
            tone: "onprimarycontainer"
            text: root.row.title
        }
        AppText {
            width: parent.width
            visible: !root.choosing && text !== ""
            role: "body"
            tone: "onprimarycontainer"
            text: root.row.subtitle
        }
        Flow {
            visible: root.choosing
            width: parent.width
            spacing: Metrics.cardActions

            Repeater {
                model: root.choosing ? root.row.actions : []

                Button {
                    required property var modelData
                    required property int index
                    height: Metrics.chipHeight
                    variant: index === root.action ? "filled" : "veil"
                    text: modelData.label
                    activeFocusOnTab: false
                    onClicked: root.actionTriggered(modelData.id)
                }
            }
        }
    }

    Row {
        visible: !root.choosing
        x: Metrics.panelPad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        Button {
            id: open
            height: Metrics.control
            text: root.row.actions[0].label
            onClicked: root.actionTriggered("")
        }
        Button {
            visible: root.row.quick !== null
            width: Math.min(implicitWidth, parent.width - open.width - parent.spacing)
            height: Metrics.control
            variant: "veil"
            text: root.row.quick?.label ?? ""
            clip: true
            onClicked: root.actionTriggered(root.row.quick.id)
        }
    }

    Rectangle {
        visible: root.selected
        anchors.fill: parent
        radius: root.shapeRadius
        color: "transparent"
        border.width: Metrics.focusRing
        border.color: root.scheme.primary
    }
}
