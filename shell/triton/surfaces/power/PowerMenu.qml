pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The power menu: greeting, one connected group of actions, and a countdown
// before anything that ends the session. A pure view; `run` reports what was
// confirmed.
FocusScope {
    id: root

    property string greeting: ""
    property string uptime: ""
    property string note: "" // shown when restarting or shutting down
    property string footer: ""

    property int current: 0
    property int pending: -1 // action counting down, or -1
    property real remaining: 1 // of the countdown, 1 to 0

    signal run(string action)
    signal cancelled

    readonly property var actions: [
        { id: "lock", text: "Lock", glyph: Icons.lock, container: "primaryContainer", content: "onprimarycontainer" },
        { id: "sleep", text: "Sleep", glyph: Icons.bedtime },
        { id: "logout", text: "Log out", glyph: Icons.logout, countdown: "Logging out" },
        { id: "restart", text: "Restart", glyph: Icons.restartAlt, countdown: "Restarting", ends: true },
        { id: "shutdown", text: "Shut down", glyph: Icons.powerSettingsNew, countdown: "Shutting down", ends: true }
    ]

    function reset() {
        stop();
        current = 0;
    }

    function stop() {
        countdown.stop();
        pending = -1;
        remaining = 1;
    }

    function confirm(index) {
        current = index;
        if (!actions[index].countdown) {
            run(actions[index].id);
            return;
        }
        pending = index;
        remaining = 1;
        countdown.restart();
    }

    function step(by) {
        current = Math.max(0, Math.min(actions.length - 1, current + by));
    }

    NumberAnimation {
        id: countdown
        target: root
        property: "remaining"
        from: 1
        to: 0
        // Time, not motion: it runs even with reduced motion.
        duration: Motion.powerCountdown
        onFinished: {
            const action = root.actions[root.pending].id;
            root.stop();
            root.run(action);
        }
    }

    Keys.onPressed: event => {
        event.accepted = true;
        // The Enter that confirmed may repeat; it must not cancel.
        if (event.isAutoRepeat && root.pending >= 0)
            return;
        if (root.pending >= 0) {
            root.stop();
            return;
        }
        const number = event.key - Qt.Key_1;
        if (number >= 0 && number < root.actions.length)
            root.current = number;
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_Backtab)
            root.step(-1);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab)
            root.step(1);
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !event.isAutoRepeat)
            root.confirm(root.current);
        else if (event.key === Qt.Key_Escape)
            root.cancelled();
        else
            event.accepted = false;
    }

    // Clicking away leaves the menu, or stops a running countdown.
    MouseArea {
        anchors.fill: parent
        onClicked: root.pending >= 0 ? root.stop() : root.cancelled()
    }

    Column {
        anchors.centerIn: parent
        spacing: Metrics.panelPad * 2
        visible: opacity > 0
        opacity: root.pending < 0 ? 1 : 0
        Behavior on opacity { Fade {} }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.cardActions

            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "display"
                text: root.greeting
            }
            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "title"
                tone: "onsurfacevariant"
                text: root.uptime
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.powerSpacing

            Repeater {
                model: root.actions

                PowerChoice {
                    required property var modelData
                    required property int index
                    glyph: modelData.glyph
                    text: modelData.text
                    container: modelData.container ?? (modelData.ends ? "tertiaryContainer" : "secondaryContainer")
                    inkRole: modelData.content ?? (modelData.ends ? "ontertiarycontainer" : "onsecondarycontainer")
                    strong: modelData.ends ?? false
                    focused: root.current === index
                    first: index === 0
                    last: index === root.actions.length - 1
                    enabled: root.pending < 0
                    onClicked: root.confirm(index)
                }
            }
        }

        // Holds its height so that nothing moves when the note comes and goes.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: pill.width
            height: Metrics.buttonHeight

            Material {
                id: pill
                width: noteRow.implicitWidth + Metrics.buttonPad * 2
                height: parent.height
                radius: height / 2
                opacity: root.note !== "" && (root.actions[root.current].ends ?? false) ? 1 : 0
                Behavior on opacity { Fade {} }

                Row {
                    id: noteRow
                    anchors.centerIn: parent
                    spacing: Metrics.buttonGap

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Icons.warning
                        fill: true
                        tone: "tertiary"
                    }
                    AppText {
                        anchors.verticalCenter: parent.verticalCenter
                        role: "label"
                        text: root.note
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.panelPad

            KeyHint { keys: ["←", "→"]; text: "move" }
            KeyHint { keys: ["Enter"]; text: "confirm" }
            KeyHint { keys: ["1–5"]; text: "jump" }
            KeyHint { keys: ["Esc"]; text: "cancel" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Metrics.panelPad
        visible: opacity > 0
        opacity: root.pending >= 0 ? 1 : 0
        Behavior on opacity { Fade {} }

        WavyRing {
            anchors.horizontalCenter: parent.horizontalCenter
            progress: root.remaining

            AppText {
                anchors.centerIn: parent
                role: "display"
                tabular: true
                text: Math.max(1, Math.ceil(root.remaining * Motion.powerCountdown / 1000))
            }
        }
        AppText {
            id: heading
            // Kept through the fade out, after `pending` has been cleared.
            property string last: ""
            anchors.horizontalCenter: parent.horizontalCenter
            role: "headline"
            text: last
            Connections {
                target: root
                function onPendingChanged() {
                    if (root.pending >= 0)
                        heading.last = root.actions[root.pending].countdown;
                }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.cardGap

            Button {
                variant: "veil"
                text: "Cancel"
                onClicked: root.stop()
            }
            AppText {
                anchors.verticalCenter: parent.verticalCenter
                role: "bodySmall"
                tone: "onsurfacevariant"
                text: "or press any key"
            }
        }
    }

    AppText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.panelPad * 2
        role: "bodySmall"
        tone: "onsurfacevariant"
        text: root.footer
    }
}
