import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.tokens

// A round app icon or contact picture, with a glyph when there is neither.
ClippingRectangle {
    id: root

    property string source: ""
    property string glyph: Icons.notifications
    property bool picture: false // fill the disc instead of sitting inside it
    property real size: Metrics.disc

    readonly property Scheme scheme: Theming.of(root)

    width: size
    height: size
    radius: size / 2
    color: scheme.veil

    Image {
        id: image
        visible: status === Image.Ready
        anchors.centerIn: parent
        width: root.picture ? root.size : Metrics.iconLg
        height: width
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Icon {
        visible: !image.visible
        anchors.centerIn: parent
        glyph: root.glyph
        size: "lg"
    }
}
