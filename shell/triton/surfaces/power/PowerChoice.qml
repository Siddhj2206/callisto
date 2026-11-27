import QtQuick
import qs.foundations
import qs.tokens

// One action in the power group. The focused one grows into a pill and names
// the key that runs it.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property string container: "secondaryContainer"
    property string content: "onsecondarycontainer"
    property bool strong: false // solid accent when focused
    property bool focused: false
    property bool first: false
    property bool last: false

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: focused && strong ? "ontertiary" : content
    readonly property real round: height / 2

    signal clicked

    implicitHeight: Metrics.powerChoice
    implicitWidth: grow.value

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.focused: focused
    Accessible.onPressAction: root.clicked()

    Spring {
        id: grow
        to: root.focused ? Metrics.powerExpanded : Metrics.powerChoice
        token: Motion.spatialFast
    }
    Spring {
        id: leftCorner
        to: root.focused || root.first ? root.round : Metrics.powerInner
        token: Motion.spatialFast
    }
    Spring {
        id: rightCorner
        to: root.focused || root.last ? root.round : Metrics.powerInner
        token: Motion.spatialFast
    }

    component Shaped: Rectangle {
        anchors.fill: parent
        // The spring overshoots; a radius past half the height is undefined.
        topLeftRadius: Math.min(leftCorner.value, root.round)
        bottomLeftRadius: topLeftRadius
        topRightRadius: Math.min(rightCorner.value, root.round)
        bottomRightRadius: topRightRadius
    }

    Shaped {
        color: root.focused && root.strong ? root.scheme.tertiary : root.scheme[root.container]
        Behavior on color { ColorFade {} }
    }
    Shaped {
        color: root.scheme[root.tone]
        opacity: pointer.pressed ? Theme.statePress : pointer.containsMouse ? Theme.stateHover : 0
        Behavior on opacity { Fade { duration: Motion.fadeFast } }
    }

    Column {
        anchors.centerIn: parent
        spacing: Metrics.cardActions
        opacity: root.focused ? 0 : 1
        Behavior on opacity { Fade {} }

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: root.glyph
            points: Metrics.powerIcon
            tone: root.tone
        }
        AppText {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "label"
            tone: root.tone
            text: root.text
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: Metrics.cardGap
        opacity: root.focused ? 1 : 0
        Behavior on opacity { Fade {} }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            fill: true
            points: Metrics.powerIconFocused
            tone: root.tone
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter

            AppText {
                role: "headline"
                tone: root.tone
                text: root.text
            }
            AppText {
                role: "bodySmall"
                tone: root.tone
                text: "Press Enter"
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
