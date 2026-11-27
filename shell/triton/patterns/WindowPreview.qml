import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// A live picture of a window, cropped to fill; its icon until there is one.
ClippingRectangle {
    id: root

    property var capture: null // a Wayland toplevel
    property string icon: ""
    property bool live: true

    readonly property Scheme scheme: Theming.of(root)

    color: scheme.surfaceContainerHighest
    radius: Metrics.radiusPanelS / 2

    Avatar {
        visible: !view.hasContent
        anchors.centerIn: parent
        source: root.icon
        glyph: Icons.apps
    }

    ScreencopyView {
        id: view
        readonly property real scale0: sourceSize.width > 0 && sourceSize.height > 0
            ? Math.max(root.width / sourceSize.width, root.height / sourceSize.height) : 0
        visible: hasContent
        anchors.centerIn: parent
        width: scale0 > 0 ? sourceSize.width * scale0 : root.width
        height: scale0 > 0 ? sourceSize.height * scale0 : root.height
        captureSource: root.capture
        live: root.live
    }
}
