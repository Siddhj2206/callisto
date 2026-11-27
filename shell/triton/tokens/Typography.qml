// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import Quickshell
import QtQuick

QtObject {
    readonly property bool board: Quickshell.env("CALLISTO_DENSITY") === "board"

    readonly property var roles: ({
        "clock": { family: "Jost", weight: 600, size: board ? 26 : 16, line: board ? 30 : 20 },
        "workspace": { family: "Jost", weight: 600, size: board ? 17 : 13, line: board ? 22 : 16 },
        "numeral": { family: "Jost", weight: 600, size: board ? 26 : 18, line: board ? 30 : 22 },
        "headline": { family: "Jost", weight: 600, size: board ? 28 : 22, line: board ? 32 : 26 },
        "title": { family: "Google Sans Flex", weight: 600, size: board ? 16 : 15, line: board ? 22 : 20 },
        "body": { family: "Google Sans Flex", weight: 400, size: board ? 15 : 13, line: board ? 21 : 18 },
        "bodySmall": { family: "Google Sans Flex", weight: 400, size: board ? 13 : 12, line: board ? 18 : 16 },
        "date": { family: "Google Sans Flex", weight: 500, size: board ? 14 : 12, line: board ? 20 : 16 },
        "label": { family: "Google Sans Flex", weight: 600, size: board ? 14 : 13, line: board ? 20 : 18 },
        "labelSmall": { family: "Google Sans Flex", weight: 600, size: board ? 13 : 12, line: board ? 18 : 16 },
    })
}
