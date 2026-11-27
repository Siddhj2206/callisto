import QtQuick
import qs.foundations
import qs.tokens
import qs

// The wallpaper behind the lock and login screens: blurred inside the shell,
// since no compositor blur reaches a session lock, and tinted.
Item {
    id: root

    property url source

    readonly property Scheme scheme: Theming.of(root)

    Rectangle {
        anchors.fill: parent
        color: root.scheme.surface
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Loader {
        id: blur
        anchors.fill: parent
        active: wallpaper.status === Image.Ready
        source: Qt.resolvedUrl("../foundations/BlurLayer.qml")
        onLoaded: item.source = wallpaper
    }
    Rectangle {
        anchors.fill: parent
        color: root.scheme.backdrop
        opacity: Theme.stateDimmed
    }
}
