import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// The top of a keyboard-driven picker: a wave badge, a bare search field, and
// whatever filters it carries (children, right-aligned).
Column {
    id: root

    default property alias trailing: extras.data
    property alias query: input.text
    readonly property bool atEnd: input.cursorPosition === input.text.length && input.selectedText === ""
    property string glyph: ""
    property string tone: "primary" // badge fill
    property string placeholder: ""

    signal edited(string text)
    signal keyPressed(var event)

    readonly property Scheme scheme: Theming.of(root)

    function focusInput() {
        input.forceActiveFocus();
    }

    Item {
        width: parent.width
        height: Metrics.launcherHeader

        WaveShape {
            id: badge
            x: Metrics.panelPad
            anchors.verticalCenter: parent.verticalCenter
            width: Metrics.control
            height: width
            color: root.scheme[root.tone]

            Icon {
                anchors.centerIn: parent
                glyph: root.glyph
                tone: "on" + root.tone
            }
        }

        TextInput {
            id: input
            anchors.left: badge.right
            anchors.leftMargin: Metrics.rowGap
            anchors.right: extras.left
            anchors.rightMargin: Metrics.rowGap
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            focus: true
            font.family: Typography.roles.title.family
            font.pixelSize: Typography.roles.title.size
            color: root.scheme.onsurface
            selectionColor: root.scheme.primary
            selectedTextColor: root.scheme.onprimary
            Accessible.name: "Search"
            onTextEdited: root.edited(text)
            Keys.onPressed: event => root.keyPressed(event)

            AppText {
                visible: input.text === ""
                anchors.fill: parent
                role: "title"
                tone: "onsurfacevariant"
                text: root.placeholder
            }
        }

        Row {
            id: extras
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPad
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.cardActions
        }
    }

    Divider {
        horizontal: true
        width: parent.width
    }
}
