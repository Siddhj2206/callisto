import QtQuick
import qs.foundations
import qs.tokens

// Something that must not be missed, such as an open microphone: a warm pill
// with an icon and a few words.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property string tone: "tertiary" // "tertiary" | "error"

    readonly property Scheme scheme: Theming.of(root)
    readonly property string ink: tone === "error" ? "onerrorcontainer" : "ontertiarycontainer"

    implicitHeight: Metrics.barSlot
    implicitWidth: row.implicitWidth + Metrics.statusPad * 2
    Accessible.role: Accessible.Indicator
    Accessible.name: text

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.tone === "error" ? root.scheme.errorContainer : root.scheme.tertiaryContainer
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Metrics.batteryGap * 2

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            fill: true
            size: "sm"
            tone: root.ink
        }
        AppText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Metrics.mediaTitleMax)
            role: "label"
            tone: root.ink
            text: root.text
        }
    }
}
