import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// Something that must not be missed, such as an open microphone: a warm pill
// with an icon and a few words.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property string tone: "tertiary" // "tertiary" | "error"
    property string actionGlyph: "" // a button inside the chip
    property string actionLabel: ""

    signal actionRequested

    readonly property Scheme scheme: Theming.of(root)
    readonly property string ink: tone === "error" ? "onerrorcontainer" : "ontertiarycontainer"

    implicitHeight: Metrics.barSlot
    implicitWidth: row.implicitWidth + Metrics.statusPad * (actionGlyph !== "" ? 1 : 2)
        + (actionGlyph !== "" ? Metrics.barPad : 0)
    Accessible.role: Accessible.Indicator
    Accessible.name: text

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.tone === "error" ? root.scheme.errorContainer : root.scheme.tertiaryContainer
    }
    Row {
        id: row
        x: Metrics.statusPad
        anchors.verticalCenter: parent.verticalCenter
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
            tabular: true
            text: root.text
        }
        IconButton {
            visible: root.actionGlyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.barSlot - Metrics.barPad * 2
            iconSize: "sm"
            variant: "veil"
            glyph: root.actionGlyph
            label: root.actionLabel
            onClicked: root.actionRequested()
        }
    }
}
