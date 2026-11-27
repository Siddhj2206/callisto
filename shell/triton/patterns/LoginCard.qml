import QtQuick
import qs.foundations
import qs.tokens

// Who is signing in, and their password. Shared by lock and greeter.
Item {
    id: root

    property string name: ""
    property string caption: ""
    property alias busy: field.busy

    signal accepted(string password)

    readonly property Scheme scheme: Theming.of(root)
    property string error: ""

    function focusInput() {
        field.focusInput();
    }

    function reset() {
        field.clear();
        field.wrong = false;
    }

    // The password was refused: say so, clear it and shake.
    function reject() {
        field.clear();
        field.wrong = true;
        field.shake();
    }

    implicitWidth: Metrics.loginCard
    implicitHeight: column.implicitHeight + Metrics.panelPad * 2

    Material {
        anchors.fill: parent
        radius: Metrics.radiusPanelM
    }

    Column {
        id: column
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        UserAvatar {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.name
        }
        AppText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            role: "headline"
            textFormat: Text.PlainText
            text: root.name
        }
        AppText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            role: "bodySmall"
            tone: root.error !== "" ? "error" : "onsurfacevariant"
            textFormat: Text.PlainText
            text: root.error !== "" ? root.error : root.busy ? "Checking…" : root.caption
        }
        PasswordField {
            id: field
            width: parent.width
            focus: true
            onAccepted: password => root.accepted(password)
        }
    }
}
