import QtQuick
import qs.foundations
import qs.tokens

// Network, sound and battery. Blue is fine, warm wants attention, red is
// urgent. Click opens quick settings, scroll changes the volume.
Pressable {
    id: root

    property string networkGlyph: ""
    property string volumeGlyph: ""
    property string batteryGlyph: ""
    property int batteryPercent: -1 // -1 = no battery
    property bool batteryRing: false
    property string health: "ok" // "ok" | "attention" | "urgent"

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: health === "urgent" ? "onerrorcontainer"
        : health === "attention" ? "ontertiarycontainer" : "onprimarycontainer"

    label: "Quick settings"
    implicitHeight: Metrics.barSlot
    implicitWidth: row.implicitWidth + Metrics.statusPad * 2
    fill: health === "urgent" ? scheme.errorContainer
        : health === "attention" ? scheme.tertiaryContainer : scheme.primaryContainer
    ink: scheme[tone]

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Metrics.statusGap

        Icon {
            visible: glyph !== ""
            glyph: root.networkGlyph
            tone: root.tone
        }
        Icon {
            visible: glyph !== ""
            glyph: root.volumeGlyph
            tone: root.tone
        }
        Row {
            visible: root.batteryPercent >= 0
            spacing: Metrics.batteryGap

            Icon {
                visible: !root.batteryRing
                glyph: root.batteryGlyph
                tone: root.tone
            }
            WaveShape {
                visible: root.batteryRing
                width: Metrics.iconMd
                height: Metrics.iconMd
                color: "transparent"
                strokeColor: Qt.alpha(root.scheme[root.tone], Math.max(0.3, root.batteryPercent / 100))
                strokeWidth: Metrics.ringStroke
            }
            AppText {
                height: Metrics.iconMd
                role: "label"
                tone: root.tone
                tabular: true
                text: root.batteryPercent + "%"
            }
        }
    }
}
