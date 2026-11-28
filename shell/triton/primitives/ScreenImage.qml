import Quickshell
import QtQuick

// A photo filling its box, decoded at the size it is shown and no larger: a
// wallpaper at full size is tens of megabytes. Boxes of one size share a copy.
Image {
    id: root

    property url file

    readonly property real ratio: QsWindow.window?.devicePixelRatio ?? 1
    readonly property bool sized: width > 0 && height > 0

    // Nothing loads until the box has a size, or it would be read in full.
    source: sized ? file : ""
    sourceSize: sized ? Qt.size(Math.ceil(width * ratio), Math.ceil(height * ratio)) : undefined
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
}
