pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.tokens

// A full-bleed image that fades to the next one only once it has loaded.
Item {
    id: root

    property url source
    property bool first: true // which of the two is in front

    onSourceChanged: load()
    Component.onCompleted: load()

    function load() {
        const back = first ? b : a;
        const front = first ? a : b;
        if (front.source == source)
            return;
        if (back.source == source && back.status === Image.Ready)
            first = !first;
        else
            back.source = source;
    }

    function arrived(image) {
        if (image.status === Image.Ready && image.source == source && image !== (first ? a : b))
            first = !first;
    }

    component Layer: Image {
        required property bool front
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: front ? 1 : 0
        onStatusChanged: root.arrived(this)
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
