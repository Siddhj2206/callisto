pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// A keyboard shortcut as keycaps: "SUPER + SHIFT + E".
Row {
    id: root

    property string keys: ""
    property string none: "Not set"

    readonly property var names: ({
        SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift", Return: "Enter", Escape: "Esc",
        BackSpace: "Backspace", Prior: "Page Up", Next: "Page Down", comma: ",", period: ".",
        slash: "/", backslash: "\\", semicolon: ";", apostrophe: "'", bracketleft: "[",
        bracketright: "]", minus: "-", equal: "=", grave: "`",
    })

    spacing: Metrics.buttonGap

    Repeater {
        model: root.keys === "" ? [] : root.keys.split(" + ")

        Keycap {
            required property string modelData
            text: root.names[modelData] ?? modelData
        }
    }
    AppText {
        visible: root.keys === ""
        role: "bodySmall"
        tone: "onsurfacevariant"
        text: root.none
    }
}
