import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// The on-screen display. When something is off, the icon circle becomes a
// wave in a warm color. Switching kind morphs the pill in place.
Item {
    id: root

    property string kind: "volume" // "volume" | "muted" | "brightness" | "micOff"
    property real value: 0

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool numeric: kind === "volume" || kind === "brightness"
    readonly property bool off: kind === "muted" || kind === "micOff"

    readonly property string glyph: {
        switch (kind) {
        case "muted": return Icons.volumeOff;
        case "micOff": return Icons.micOff;
        case "brightness": return value < 0.34 ? Icons.brightnessLow : value < 0.67 ? Icons.brightnessMedium : Icons.brightnessHigh;
        default: return value <= 0 ? Icons.volumeMute : value < 0.5 ? Icons.volumeDown : Icons.volumeUp;
        }
    }

    implicitHeight: Metrics.osdHeight
    implicitWidth: morph.value
    Accessible.role: Accessible.AlertMessage
    Accessible.name: kind === "micOff" ? "Microphone off" : kind === "muted" ? "Muted"
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

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Metrics.osdDisc
                height: Metrics.osdDisc

                Rectangle {
                    visible: !root.off
                    anchors.fill: parent
                    radius: width / 2
                    color: root.scheme.veil
                }
                WaveShape {
                    visible: root.off
                    anchors.fill: parent
                    color: root.kind === "micOff" ? root.scheme.errorContainer : root.scheme.tertiaryContainer
                }
                Icon {
                    anchors.centerIn: parent
                    glyph: root.glyph
                    fill: true
                    tone: root.kind === "micOff" ? "onerrorcontainer" : root.off ? "ontertiarycontainer" : "onsurface"
                }
            }

            LevelTrack {
                visible: root.kind !== "micOff"
                anchors.verticalCenter: parent.verticalCenter
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
        }
    }
}
