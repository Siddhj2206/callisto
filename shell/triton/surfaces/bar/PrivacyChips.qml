import QtQuick
import qs
import qs.patterns
import qs.tokens

// The microphone and camera chips, in the bar or alone while it is hidden.
Row {
    id: root

    property string micApp: ""
    property bool micMuted: false
    property string video: "" // "" | "camera" | "screen"

    readonly property bool active: micApp !== "" || video !== ""

    spacing: Metrics.barGap

    IndicatorChip {
        visible: root.video !== ""
        tone: "error"
        glyph: Icons.videocam
        text: root.video === "camera" ? "Camera" : "Screen shared"
    }
    IndicatorChip {
        visible: root.micApp !== ""
        glyph: root.micMuted ? Icons.micOff : Icons.mic
        text: root.micApp
    }
}
