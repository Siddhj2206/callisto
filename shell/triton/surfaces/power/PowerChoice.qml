import QtQuick
import qs.foundations
import qs.tokens

// One action in the power group. The focused one grows into a pill and names
// the key that runs it.
Pressable {
    id: root

    property string glyph: ""
    property string text: ""
    property string container: "secondaryContainer"
    property string inkRole: "onsecondarycontainer"
    property bool strong: false // solid accent when focused
    property bool focused: false
    property bool first: false
    property bool last: false

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: focused && strong ? "ontertiary" : inkRole

    radius: focused || first ? height / 2 : Metrics.powerInner
    radiusRight: focused || last ? height / 2 : Metrics.powerInner
    fill: focused && strong ? scheme.tertiary : scheme[container]
    ink: scheme[tone]
    label: text
    activeFocusOnTab: false // the menu moves the focus itself

    implicitHeight: Metrics.powerChoice
    implicitWidth: grow.value

    Accessible.focused: focused

    Spring {
        id: grow
        to: root.focused ? Metrics.powerExpanded : Metrics.powerChoice
        token: Motion.spatialFast
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
}
