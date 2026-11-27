import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// A person: their initial in a wave.
WaveShape {
    id: root

    property string name: ""
    property real size: Metrics.avatarLarge

    width: size
    height: size
    color: Theming.of(root).tertiaryContainer

    AppText {
        anchors.centerIn: parent
        role: "headline"
        tone: "ontertiarycontainer"
        textFormat: Text.PlainText
        text: root.name.charAt(0).toUpperCase()
    }
}
