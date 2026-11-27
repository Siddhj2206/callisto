import QtQuick
import qs
import qs.patterns
import qs.tokens

// The recording, camera and microphone chips on the bar.
Row {
    id: root

    property string micApp: ""
    property bool micMuted: false
    property string video: "" // "" | "camera" | "screen"

    property string recording: "" // time so far, while the screen is recorded

    readonly property bool active: micApp !== "" || video !== "" || recording !== ""

    signal stopRequested

    spacing: Metrics.barGap

    IndicatorChip {
        visible: root.recording !== ""
        tone: "error"
        glyph: Icons.fiberManualRecord
        text: "Recording " + root.recording
        actionGlyph: Icons.stop
        actionLabel: "Stop recording"
        onActionRequested: root.stopRequested()
    }
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
