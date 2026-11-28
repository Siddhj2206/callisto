import QtQuick
import qs.foundations
import qs.tokens

// Where one is in a list that does not fit, and a handle to drag. Put it in the
// Flickable it follows, as `ScrollBar { parent: list; target: list }`, and leave
// `scrollbarHit` free at that side: it is drawn over whatever is there.
Item {
    id: root

    required property Flickable target

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool needed: target.visibleArea.heightRatio < 1
    readonly property bool engaged: pointer.containsMouse || pointer.pressed
    readonly property real thumbHeight: Math.min(height, Math.max(Metrics.scrollbarThumb, height * target.visibleArea.heightRatio))
    // The share of the travel that is behind us, 0..1.
    readonly property real progress: needed
        ? Math.max(0, Math.min(1, target.visibleArea.yPosition / (1 - target.visibleArea.heightRatio))) : 0

    // Put the thumb's top at `y`.
    function drag(y) {
        const travel = height - thumbHeight;
        if (travel > 0)
            target.contentY = target.originY + Math.max(0, Math.min(1, y / travel)) * (target.contentHeight - target.height);
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: Metrics.scrollbarHit
    visible: needed

    Rectangle {
        id: thumb
        anchors.right: parent.right
        anchors.rightMargin: Metrics.scrollbarInset
        y: root.progress * (root.height - height)
        width: root.engaged ? Metrics.scrollbarWide : Metrics.scrollbar
        height: root.thumbHeight
        radius: width / 2
        color: root.engaged ? root.scheme.onsurfacevariant : root.scheme.outline
        Behavior on color { ColorFade {} }
    }

    MouseArea {
        id: pointer

        // Where in the thumb it was taken hold of.
        property real grip: 0

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onPressed: mouse => {
            // A press beside the thumb brings its middle to the pointer.
            const on = mouse.y >= thumb.y && mouse.y <= thumb.y + thumb.height;
            grip = on ? mouse.y - thumb.y : thumb.height / 2;
            root.drag(mouse.y - grip);
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.drag(mouse.y - grip);
        }
    }
}
