import QtQuick
import qs
import qs.foundations
import qs.tokens

// A choice that is easier to see than to name: a preview (children), a title
// and a line about it.
Pressable {
    id: root

    default property alias preview: stage.data
    property string title: ""
    property string caption: ""
    property bool selected: false

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: selected ? "onsecondarycontainer" : "onsurface"

    implicitWidth: Metrics.optionCard
    implicitHeight: body.height + Metrics.panelPad * 2
    radius: Metrics.listOuter
    fill: selected ? scheme.secondaryContainer : scheme.veil
    ink: scheme[tone]
    label: title + (selected ? ", selected" : "")

    Column {
        id: body
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.buttonGap

        Item {
            id: stage
            width: parent.width
            height: Metrics.optionPreview
        }
        Row {
            spacing: Metrics.buttonGap

            Icon {
                visible: root.selected
                anchors.verticalCenter: parent.verticalCenter
                glyph: Icons.checkCircle
                fill: true
                tone: "primary"
            }
            AppText {
                anchors.verticalCenter: parent.verticalCenter
                role: "label"
                tone: root.tone
                text: root.title
            }
        }
        AppText {
            width: parent.width
            role: "bodySmall"
            tone: "onsurfacevariant"
            wrapMode: Text.WordWrap
            text: root.caption
        }
    }
}
