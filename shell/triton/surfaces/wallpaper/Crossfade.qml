pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// A full-bleed image that fades to the next one only once it has loaded, and
// then lets the old one go.
Item {
    id: root

    property url source
    property bool first: true // which of the two is in front

    onSourceChanged: load()
    Component.onCompleted: load()

    function load() {
        const back = first ? b : a;
        const front = first ? a : b;
        if (front.file == source)
            return;
        if (back.file == source && back.status === Image.Ready)
            first = !first;
        else
            back.file = source;
    }

    function arrived(image) {
        if (image.status === Image.Ready && image.file == source && image !== (first ? a : b))
            first = !first;
    }

    component Layer: ScreenImage {
        required property bool front
        anchors.fill: parent
        opacity: front ? 1 : 0
        onStatusChanged: root.arrived(this)
        // Faded out, unless it is already loading the next one.
        onOpacityChanged: {
            if (!front && opacity === 0 && file != root.source)
                file = "";
        }
        Behavior on opacity { Fade { duration: Motion.fadeSlow } }
    }

    Layer {
        id: a
        front: root.first
    }
    Layer {
        id: b
        front: !root.first
    }
}
