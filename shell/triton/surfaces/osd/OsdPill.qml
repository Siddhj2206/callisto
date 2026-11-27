import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The on-screen display. When something is off, the icon circle becomes a
// wave in a warm color. Switching kind morphs the pill in place.
Item {
    id: root

    property string kind: "volume" // "volume" | "muted" | "brightness" | "micOff"
    property real value: 0
    property string detail: ""
    property var track: null // { title, artist, art, playing }
    signal saverRequested

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool numeric: kind === "volume" || kind === "brightness"
    readonly property bool off: kind === "muted" || kind === "micOff"
    readonly property bool warning: kind === "micOff" || kind === "battery"
    readonly property bool isTrack: kind === "track"

    readonly property string glyph: {
        switch (kind) {
        case "muted": return Icons.volumeOff;
        case "micOff": return Icons.micOff;
        case "battery": return Icons.batteryAlert;
        case "brightness": return value < 0.34 ? Icons.brightnessLow : value < 0.67 ? Icons.brightnessMedium : Icons.brightnessHigh;
        default: return Icons.volume(value, false);
        }
    }

    implicitHeight: Metrics.osdHeight
    implicitWidth: morph.value
    Accessible.role: Accessible.AlertMessage
    Accessible.name: kind === "battery" ? "Battery " + Math.round(value * 100) + " percent. " + detail
        : isTrack ? (track?.playing ? "Playing " : "Paused ") + (track?.title ?? "")
        : kind === "micOff" ? "Microphone off" : kind === "muted" ? "Muted"
        : kind + " " + Math.round(value * 100)

    Spring {
        id: morph
        to: content.implicitWidth + Metrics.osdStart + Metrics.osdEnd
        token: Motion.spatialFast
        epsilon: 0.2
    }

    Material {
        anchors.fill: parent
        radius: height / 2
    }

    Item {
        anchors.fill: parent
        clip: morph.running

        Row {
            id: content
            x: Metrics.osdStart
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.osdGap

            PlayerArt {
                visible: root.isTrack
                anchors.verticalCenter: parent.verticalCenter
                size: Metrics.osdDisc
                source: root.track?.art ?? ""
            }

            Item {
                visible: !root.isTrack
                anchors.verticalCenter: parent.verticalCenter
                width: Metrics.osdDisc
                height: Metrics.osdDisc

                Rectangle {
                    visible: !root.off && !root.warning
                    anchors.fill: parent
                    radius: width / 2
                    color: root.scheme.veil
                }
                WaveShape {
                    visible: root.off || root.warning
                    anchors.fill: parent
                    color: root.warning ? root.scheme.errorContainer : root.scheme.tertiaryContainer
                }
                Icon {
                    anchors.centerIn: parent
                    glyph: root.glyph
                    fill: true
                    tone: root.warning ? "onerrorcontainer" : root.off ? "ontertiarycontainer" : "onsurface"
                }
            }

            Slider {
                visible: !root.warning && !root.isTrack
                anchors.verticalCenter: parent.verticalCenter
                interactive: false
                width: Metrics.osdTrackWidth
                trackHeight: Metrics.osdTrackHeight
                handleHeight: Metrics.osdTrackHeight + Metrics.osdHandleOver * 2
                value: root.value
                off: root.off
            }

            AppText {
                visible: root.numeric
                anchors.verticalCenter: parent.verticalCenter
                width: Metrics.osdValueWidth
                horizontalAlignment: Text.AlignRight
                role: "numeral"
                tabular: true
                text: Math.round(root.value * 100)
            }

            AppText {
                visible: root.off
                anchors.verticalCenter: parent.verticalCenter
                role: "label"
                text: root.kind === "micOff" ? "Microphone off" : "Muted"
            }

            Column {
                visible: root.isTrack
                anchors.verticalCenter: parent.verticalCenter

                AppText {
                    width: Math.min(implicitWidth, Metrics.mediaTitleMax)
                    role: "label"
                    textFormat: Text.PlainText
                    text: root.track?.title ?? ""
                }
                AppText {
                    visible: text !== ""
                    width: Math.min(implicitWidth, Metrics.mediaTitleMax)
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    textFormat: Text.PlainText
                    text: root.track?.artist ?? ""
                }
            }

            Icon {
                visible: root.isTrack
                anchors.verticalCenter: parent.verticalCenter
                glyph: root.track?.playing ? Icons.playArrow : Icons.pause
                fill: true
            }

            Column {
                visible: root.kind === "battery"
                anchors.verticalCenter: parent.verticalCenter

                AppText {
                    role: "label"
                    text: "Battery " + Math.round(root.value * 100) + "%"
                }
                AppText {
                    visible: text !== ""
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    text: root.detail
                }
            }

            Button {
                visible: root.kind === "battery"
                anchors.verticalCenter: parent.verticalCenter
                text: "Saver"
                onClicked: root.saverRequested()
            }
        }
    }
}
