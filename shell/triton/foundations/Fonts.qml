import QtQuick

// The bundled fonts. Instantiate once per Quickshell entry point.
Item {
    Repeater {
        model: [
            "Jost-Regular", "Jost-Medium", "Jost-SemiBold",
            "GoogleSansFlex-Regular", "GoogleSansFlex-Medium", "GoogleSansFlex-SemiBold",
            "JetBrainsMono-Regular", "JetBrainsMono-Medium", "JetBrainsMono-SemiBold",
            "TritonSymbols", "TritonSymbols-Filled",
        ]
        Item {
            id: face
            required property string modelData
            FontLoader { source: Qt.resolvedUrl("../fonts/" + face.modelData + ".ttf") }
        }
    }
}
