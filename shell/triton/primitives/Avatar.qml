import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.tokens

// A round app icon or contact picture, with a glyph when there is neither.
Rectangle {
    id: root

    property string source: ""
    property string glyph: Icons.notifications
    property bool picture: false // fill the disc instead of sitting inside it
    property real size: Metrics.disc
    property real iconSize: Metrics.iconLg
    property string tone: "onsurface"

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool shown: picture ? photo.item?.ready === true : image.status === Image.Ready

    width: size
    height: size
    radius: size / 2
    color: scheme.veil

    component Source: Image {
        source: root.source
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // An icon sits inside the disc and needs no clipping, which costs an
    // offscreen layer for each one in a long list.
    Source {
        id: image
        visible: !root.picture && root.shown
        source: root.picture ? "" : root.source
        anchors.centerIn: parent
        width: root.iconSize
        height: width
    }
    Loader {
        id: photo
        anchors.fill: parent
        active: root.picture && root.source !== ""
        visible: root.shown
        sourceComponent: ClippingRectangle {
            readonly property bool ready: face.status === Image.Ready

            radius: root.radius
            color: "transparent"

            Source {
                id: face
                anchors.fill: parent
            }
        }
    }
    Icon {
        visible: !root.shown
        anchors.centerIn: parent
        glyph: root.glyph
        size: "lg"
        tone: root.tone
    }
}
