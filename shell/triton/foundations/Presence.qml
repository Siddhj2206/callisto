import QtQuick
import qs.tokens

// Enter and exit for anything that appears or disappears. Content springs in
// from an offset and/or a smaller scale, and fades out in place. A window
// hosting a Presence binds `visible: presence.mapped` so it stays up until the
// exit has finished.
Item {
    id: root

    property bool show: false
    property real fromY: 0
    property real fromScale: 1
    property var token: Motion.spatialDefault

    readonly property bool mapped: show || opacity > 0

    opacity: show ? 1 : 0
    scale: fromScale + (1 - fromScale) * travel.value
    transform: Translate { y: root.fromY * (1 - travel.value) }

    Behavior on opacity { Fade {} }

    onShowChanged: {
        if (show)
            travel.to = 1;
    }
    onOpacityChanged: {
        if (!show && opacity === 0) {
            travel.to = 0;
            travel.snap(0);
        }
    }

    Spring {
        id: travel
        token: root.token
        epsilon: 0.001
    }

    Component.onCompleted: {
        if (show) {
            travel.to = 1;
            travel.snap(1);
        }
    }
}
