pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The lock screen over its backdrop: clock, what is waiting (without its
// content), the login card and a little status. A pure view.
Item {
    id: root

    property url wallpaper
    property string date: ""
    property string time: ""
    property string name: ""
    property string caption: ""
    property string error: ""
    property bool busy: false
    property var waiting: [] // [{ app, count }], never any content
    property string networkGlyph: ""
    property string batteryGlyph: ""
    property int batteryPercent: -1

    signal submitted(string password)

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool roomy: width >= Metrics.loginCard + (Metrics.lockNotifications + Metrics.lockSide * 2) * 2
    readonly property int waitingCount: waiting.reduce((sum, w) => sum + w.count, 0)

    function reset() {
        card.reset();
        card.focusInput();
    }

    function reject() {
        card.reject();
    }

    SessionBackdrop {
        anchors.fill: parent
        source: root.wallpaper
    }

    // A click anywhere returns typing to the password field.
    MouseArea {
        anchors.fill: parent
        onClicked: card.focusInput()
    }

    Column {
        id: top
        anchors.horizontalCenter: parent.horizontalCenter
        y: Metrics.lockTop

        // The clock gives way before the card does on a short screen.
        readonly property real room: card.y - y - Metrics.panelPad - dateText.height
        readonly property real clockSize: Math.max(Typography.roles.display.size,
            Math.min(Typography.roles.hero.size, room))

        AppText {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            role: "headline"
            text: root.date
        }
        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "hero"
            tabular: true
            font.pixelSize: top.clockSize
            lineHeight: top.clockSize
            text: root.time
        }
    }

    LoginCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.loginBottom
        width: Math.min(implicitWidth, parent.width - Metrics.panelPad * 2)
        name: root.name
        caption: root.caption
        error: root.error
        busy: root.busy
        focus: true
        onAccepted: password => root.submitted(password)
    }

    Column {
        visible: root.roomy && root.waiting.length > 0
        anchors.left: parent.left
        anchors.leftMargin: Metrics.lockSide
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.lockSide
        width: Metrics.lockNotifications
        spacing: Metrics.listGap

        Row {
            spacing: Metrics.buttonGap
            bottomPadding: Metrics.cardActions

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Icons.visibilityOff
                size: "sm"
                tone: "onsurfacevariant"
            }
            AppText {
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                tone: "onsurfacevariant"
                text: root.waitingCount + (root.waitingCount === 1 ? " notification" : " notifications") + " · content hidden"
            }
        }

        Repeater {
            model: root.waiting.slice(0, 3)

            ListRow {
                required property var modelData
                required property int index
                width: parent.width
                enabled: false
                first: index === 0
                last: index === Math.min(root.waiting.length, 3) - 1
                glyph: Icons.notifications
                title: modelData.app
                subtitle: modelData.count === 1 ? "1 notification" : modelData.count + " notifications"
            }
        }
    }

    Material {
        visible: status.width > 0
        anchors.right: parent.right
        anchors.rightMargin: Metrics.lockSide
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.lockSide
        width: status.width + Metrics.buttonPad * 2
        height: Metrics.buttonHeight
        radius: height / 2

        Row {
            id: status
            anchors.centerIn: parent
            spacing: Metrics.statusGap

            Icon {
                visible: root.networkGlyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                glyph: root.networkGlyph
            }
            Row {
                visible: root.batteryPercent >= 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.batteryGap

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: root.batteryGlyph
                }
                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "label"
                    text: root.batteryPercent + "%"
                }
            }
        }
    }
}
