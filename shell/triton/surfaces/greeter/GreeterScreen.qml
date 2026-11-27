pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The login screen: who, their password, and the way to turn the machine off.
// A pure view.
Item {
    id: root

    property url wallpaper
    property string date: ""
    property string time: ""
    property var users: [] // [{ login, name }]
    property int selected: 0
    property bool busy: false
    property string error: ""
    property string hint: ""
    property string networkGlyph: ""
    property string batteryGlyph: ""
    property int batteryPercent: -1

    signal picked(int index)
    signal submitted(string password)
    signal restartRequested
    signal shutDownRequested

    readonly property var user: users[selected] ?? null

    function reset() {
        field.clear();
        field.wrong = false;
        field.focusInput();
    }

    function reject() {
        field.clear();
        field.wrong = true;
        field.shake();
        field.focusInput();
    }

    onSelectedChanged: reset()

    SessionBackdrop {
        anchors.fill: parent
        source: root.wallpaper
    }

    MouseArea {
        anchors.fill: parent
        onClicked: field.focusInput()
    }

    Row {
        x: Metrics.lockSide
        y: Metrics.lockSide
        spacing: Metrics.rowGap

        OsLogo {
            width: Metrics.brandMark
            height: width
        }
        AppText {
            anchors.verticalCenter: parent.verticalCenter
            role: "headline"
            text: "Callisto"
        }
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: Metrics.lockSide
        y: Metrics.lockSide

        AppText {
            anchors.right: parent.right
            role: "display"
            tabular: true
            text: root.time
        }
        AppText {
            anchors.right: parent.right
            role: "title"
            text: root.date
        }
    }

    Column {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Metrics.cardActions

        // The selected person stays centred; the rest scroll past.
        ListView {
            id: people
            width: parent.width
            height: Metrics.avatarRing
            orientation: ListView.Horizontal
            spacing: Metrics.panelPad
            model: root.users
            currentIndex: root.selected
            interactive: false
            preferredHighlightBegin: (width - Metrics.avatarRing) / 2
            preferredHighlightEnd: (width + Metrics.avatarRing) / 2
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: Motion.reduce ? 0 : Motion.fadeSlow

            delegate: Pressable {
                id: person
                required property var modelData
                required property int index
                readonly property bool current: index === root.selected

                width: current ? Metrics.avatarRing : Metrics.avatarLarge
                height: Metrics.avatarRing
                radius: width / 2
                label: modelData.name
                activeFocusOnTab: false
                onClicked: {
                    root.picked(index);
                    field.focusInput();
                }

                WavyRing {
                    visible: person.current
                    anchors.centerIn: parent
                    size: Metrics.avatarRing
                    tone: "primary"
                }
                UserAvatar {
                    anchors.centerIn: parent
                    name: person.modelData.name
                    size: person.current ? Metrics.avatarSelected : Metrics.avatarLarge
                }
            }
        }

        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "display"
            textFormat: Text.PlainText
            text: root.user?.name ?? "No users"
        }

        PasswordField {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(Metrics.loginCard, parent.width - Metrics.panelPad * 2)
            focus: true
            busy: root.busy
            submitLabel: "Sign in"
            onAccepted: password => root.submitted(password)
            // With nothing typed, the arrows choose who is signing in.
            Keys.onPressed: event => {
                const step = event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Right ? 1 : 0;
                if (step === 0 || field.text !== "")
                    return;
                root.picked(root.selected + step);
                event.accepted = true;
            }
        }

        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "bodySmall"
            tone: root.error !== "" ? "error" : "onsurfacevariant"
            textFormat: Text.PlainText
            text: root.error !== "" ? root.error : root.busy ? "Signing in…" : root.hint
        }
    }

    MachineStatus {
        anchors.left: parent.left
        anchors.leftMargin: Metrics.lockSide
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.lockSide
        networkGlyph: root.networkGlyph
        batteryGlyph: root.batteryGlyph
        batteryPercent: root.batteryPercent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Metrics.lockSide
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.lockSide
        spacing: Metrics.rowGap

        IconButton {
            variant: "veil"
            size: Metrics.buttonHeight
            glyph: Icons.restartAlt
            label: "Restart"
            onClicked: root.restartRequested()
        }
        IconButton {
            variant: "veil"
            size: Metrics.buttonHeight
            glyph: Icons.powerSettingsNew
            label: "Shut down"
            onClicked: root.shutDownRequested()
        }
    }
}
