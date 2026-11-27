import QtQuick
import qs.foundations
import qs.tokens

// A single-line pill field.
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false

    signal accepted

    readonly property Scheme scheme: Theming.of(root)

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: Metrics.fieldHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.scheme.veil
        border.width: input.activeFocus ? Metrics.focusRing : 0
        border.color: root.scheme.primary
    }

    AppText {
        visible: input.text === ""
        anchors.fill: input
        role: "body"
        tone: "onsurfacevariant"
        text: root.placeholder
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Metrics.fieldPad
        anchors.rightMargin: Metrics.fieldPad
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        activeFocusOnTab: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        font.family: Typography.roles.body.family
        font.pixelSize: Typography.roles.body.size
        color: root.scheme.onsurface
        selectionColor: root.scheme.primary
        selectedTextColor: root.scheme.onprimary
        Accessible.name: root.placeholder
        onAccepted: root.accepted()
    }
}
