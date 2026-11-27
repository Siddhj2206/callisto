import QtQuick

// The system's mark. The wave is the shell's motif; this names the OS.
Image {
    source: Qt.resolvedUrl("../assets/callisto-logo.png")
    sourceSize: Qt.size(width * 2, height * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
