import QtQuick
import qs.foundations
import qs.tokens

// A labelled pill button.
Pressable {
    id: root

    property string text: ""
    property string glyph: ""
    property string variant: "filled" // "filled" | "container" | "veil" | "text"

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: variant === "filled" ? "onprimary"
        : variant === "container" ? "onprimarycontainer"
        : variant === "text" ? "primary" : "onsurface"

    label: text
    implicitHeight: Metrics.buttonHeight
    implicitWidth: row.implicitWidth + Metrics.buttonPad * 2
    ink: scheme[tone]
    fill: variant === "filled" ? scheme.primary
        : variant === "container" ? scheme.primaryContainer
        : variant === "veil" ? scheme.veil : "transparent"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Metrics.buttonGap

        Icon {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            tone: root.tone
        }
        AppText {
            anchors.verticalCenter: parent.verticalCenter
            role: "label"
            tone: root.tone
            text: root.text
        }
    }
}
