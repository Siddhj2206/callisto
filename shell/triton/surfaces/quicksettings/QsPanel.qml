pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.tokens

// The quick settings contents: the main page and one drill-in page that slides
// in over it. Height follows whichever is showing.
Item {
    id: root

    default property alias mainPage: main.data
    property Component detail: null // null shows the main page

    // Kept while sliding back out.
    property Component shown: null
    onDetailChanged: {
        if (detail)
            shown = detail;
    }

    implicitWidth: Metrics.panelWidth
    implicitHeight: height_.value

    // Goes to the start without sliding, for when the panel reopens.
    function rest() {
        slide.snap(detail ? 1 : 0);
        height_.snap(height_.to);
    }

    Spring {
        id: slide
        to: root.detail ? 1 : 0
        token: Motion.spatialDefault
        epsilon: 0.001
        onRunningChanged: {
            if (!running && !root.detail)
                root.shown = null;
        }
    }

    readonly property Item current: detail && loader.item ? loader.item : main.children[0] ?? null

    Spring {
        id: height_
        to: (root.current?.implicitHeight ?? 0) + Metrics.panelPad * 2
        token: Motion.spatialDefault
        epsilon: 0.5
    }

    Item {
        id: main
        x: Metrics.panelPad - root.width * slide.value
        y: Metrics.panelPad
        width: root.width - Metrics.panelPad * 2
        enabled: root.detail === null
        visible: slide.value < 0.999
    }

    Loader {
        id: loader
        x: Metrics.panelPad + root.width * (1 - slide.value)
        y: Metrics.panelPad
        width: root.width - Metrics.panelPad * 2
        sourceComponent: root.detail ?? root.shown
        enabled: root.detail !== null
    }
}
