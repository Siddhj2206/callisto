import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// The password pill: reveal for a moment, submit, and shake when refused.
Item {
    id: root

    property alias text: input.text
    property bool busy: false
    property bool wrong: false
    property bool revealed: false

    signal accepted(string password)

    readonly property Scheme scheme: Theming.of(root)

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
        revealed = false;
    }

    function shake() {
        if (!Motion.reduce)
            nudge.restart();
    }

    function submit() {
        if (!busy && input.text !== "")
            accepted(input.text);
    }

    implicitHeight: Metrics.lockField

    transform: Translate { id: shift }

    SequentialAnimation {
        id: nudge
        NumberAnimation { target: shift; property: "x"; to: -Metrics.shake; duration: Motion.fadeFast }
        NumberAnimation { target: shift; property: "x"; to: Metrics.shake; duration: Motion.fadeFast }
        NumberAnimation { target: shift; property: "x"; to: -Metrics.shake / 2; duration: Motion.fadeFast }
        NumberAnimation { target: shift; property: "x"; to: 0; duration: Motion.fadeFast }
    }

    Timer {
        running: root.revealed
        interval: Motion.passwordReveal
        onTriggered: root.revealed = false
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.wrong ? root.scheme.errorContainer : root.scheme.veil
        border.width: input.activeFocus ? Metrics.focusRing : 0
        border.color: root.wrong ? root.scheme.error : root.scheme.primary
        Behavior on color { ColorFade {} }
    }

    Icon {
        id: leading
        x: Metrics.fieldPad
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.lock
        tone: "onsurfacevariant"
    }

    TextInput {
        id: input
        anchors.left: leading.right
        anchors.leftMargin: Metrics.rowGap
        anchors.right: eye.left
        anchors.rightMargin: Metrics.rowGap
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        focus: true
        readOnly: root.busy
        echoMode: root.revealed ? TextInput.Normal : TextInput.Password
        // Never offered to input methods or kept for prediction.
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText
        font.family: Typography.roles.title.family
        font.pixelSize: Typography.roles.title.size
        color: root.scheme.onsurface
        selectionColor: root.scheme.primary
        selectedTextColor: root.scheme.onprimary
        Accessible.name: "Password"
        onTextEdited: root.wrong = false
        onAccepted: root.submit()
        Keys.onEscapePressed: root.clear()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
                root.clear();
                event.accepted = true;
            }
        }
    }

    IconButton {
        id: eye
        anchors.right: go.left
        anchors.verticalCenter: parent.verticalCenter
        size: Metrics.control
        glyph: root.revealed ? Icons.visibilityOff : Icons.visibility
        label: root.revealed ? "Hide password" : "Show password"
        activeFocusOnTab: false
        onClicked: root.revealed = !root.revealed
    }
    IconButton {
        id: go
        anchors.right: parent.right
        anchors.rightMargin: (root.height - size) / 2
        anchors.verticalCenter: parent.verticalCenter
        size: Metrics.control
        variant: root.text !== "" ? "filled" : "veil"
        glyph: Icons.arrowForward
        label: "Unlock"
        activeFocusOnTab: false
        onClicked: root.submit()
    }
}
