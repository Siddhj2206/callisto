import QtQuick
import qs.foundations
import qs.tokens

// A level: filled part, handle, rest. Interactive by default (drag, click,
// arrow keys, scroll); with `interactive` off it is a read-only meter.
// While dragging, the fill follows the pointer exactly; otherwise it springs.
Item {
    id: root

    property real value: 0 // 0..1
    property bool interactive: true
    property bool off: false
    property string label: ""
    property real trackHeight: Metrics.sliderTrack
    property real handleHeight: Metrics.sliderHandle

    signal moved(real value)

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool dragging: pointer.pressed
    property real dragValue: 0

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function move(v) {
        dragValue = clamp(v);
        moved(dragValue);
    }

    implicitWidth: Metrics.osdTrackWidth
    implicitHeight: handleHeight
    activeFocusOnTab: interactive
    Accessible.role: Accessible.Slider
    Accessible.name: label
    Keys.onLeftPressed: moved(clamp(value - 0.05))
    Keys.onRightPressed: moved(clamp(value + 0.05))

    Spring {
        id: level
        to: root.off ? 0 : root.clamp(root.value)
        token: Motion.spatialFast
        epsilon: 0.001
    }

    // Centre of the handle.
    readonly property real position: Metrics.sliderHandleWidth / 2
        + (width - Metrics.sliderHandleWidth) * clamp(dragging ? dragValue : level.value)
    readonly property real cut: off ? 0 : Metrics.sliderHandleWidth / 2 + Metrics.sliderGap

    Rectangle {
        width: Math.max(0, root.position - root.cut)
        height: root.trackHeight
        anchors.verticalCenter: parent.verticalCenter
        color: root.scheme.primary
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Metrics.sliderInnerRadius
        bottomRightRadius: Metrics.sliderInnerRadius
    }
    Rectangle {
        x: root.off ? 0 : root.position + root.cut
        width: Math.max(0, root.width - x)
        height: root.trackHeight
        anchors.verticalCenter: parent.verticalCenter
        color: root.scheme.veilHi
        topLeftRadius: root.off ? height / 2 : Metrics.sliderInnerRadius
        bottomLeftRadius: root.off ? height / 2 : Metrics.sliderInnerRadius
        topRightRadius: height / 2
        bottomRightRadius: height / 2
    }
    Rectangle {
        visible: !root.off
        x: root.position - width / 2
        width: Metrics.sliderHandleWidth
        height: root.handleHeight
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2
        color: root.activeFocus ? root.scheme.onsurface : root.scheme.primary
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => root.move(mouse.x / width)
        onPositionChanged: mouse => root.move(mouse.x / width)
        onWheel: wheel => root.moved(root.clamp(root.value + wheel.angleDelta.y / 120 * 0.05))
    }
}
