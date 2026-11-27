import QtQuick
import qs
import qs.tokens

// The base of everything clickable: fill, hover and press layers, keyboard
// focus ring, and the press shape change. Children are drawn on the fill.
Item {
    id: root

    default property alias content: holder.data
    property color fill: "transparent"
    property color ink: Theming.of(root).onsurface // color of the state layer
    property real radius: height / 2
    property real radiusRight: radius // differs in connected groups
    property bool interactive: true
    property string label: "" // accessible name

    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed
    readonly property real shapeRadius: morph.value

    signal clicked
    // The wheel is left to the list underneath unless this is set.
    property bool takesWheel: false
    signal scrolled(real steps)

    activeFocusOnTab: interactive
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    Spring {
        id: morph
        to: root.pressed ? Math.min(root.radius, Metrics.pressRadius) : root.radius
        token: Motion.spatialFast
    }
    Spring {
        id: morphRight
        to: root.pressed ? Math.min(root.radiusRight, Metrics.pressRadius) : root.radiusRight
        token: Motion.spatialFast
    }

    // The spring overshoots; a corner radius past half the height is undefined.
    component Shaped: Rectangle {
        property real grown: 0 // how far outside the control it is drawn
        topLeftRadius: Math.min(morph.value, root.height / 2) + grown
        bottomLeftRadius: topLeftRadius
        topRightRadius: Math.min(morphRight.value, root.height / 2) + grown
        bottomRightRadius: topRightRadius
    }

    Shaped {
        anchors.fill: parent
        color: root.fill
        Behavior on color { ColorFade {} }
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    Shaped {
        anchors.fill: parent
        color: root.ink
        opacity: !root.interactive ? 0 : root.pressed ? Theme.statePress : root.hovered ? Theme.stateHover : 0
        Behavior on opacity { Fade { duration: Motion.fadeFast } }
    }

    Shaped {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -(Metrics.focusOffset + Metrics.focusRing)
        grown: Metrics.focusOffset
        color: "transparent"
        border.width: Metrics.focusRing
        border.color: Theming.of(root).onsurface
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => {
            if (!root.takesWheel) {
                wheel.accepted = false;
                return;
            }
            const steps = wheel.angleDelta.y / 120;
            if (steps !== 0)
                root.scrolled(steps);
        }
    }
}
