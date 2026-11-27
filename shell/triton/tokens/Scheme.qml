// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

import QtQuick

// One color scheme: the Material roles plus the materials derived from them.
QtObject {
    property color primary
    property color onprimary
    property color primaryContainer
    property color onprimarycontainer
    property color secondary
    property color onsecondary
    property color secondaryContainer
    property color onsecondarycontainer
    property color tertiary
    property color ontertiary
    property color tertiaryContainer
    property color ontertiarycontainer
    property color error
    property color onerror
    property color errorContainer
    property color onerrorcontainer
    property color surface
    property color surfaceContainerLowest
    property color surfaceContainerLow
    property color surfaceContainer
    property color surfaceContainerHigh
    property color surfaceContainerHighest
    property color onsurface
    property color onsurfacevariant
    property color outline
    property color outlineVariant
    property color signalWarn
    property color signalInfo

    property color ink
    property real micaAlpha
    property real glassAlpha
    property real thickAlpha
    property real veilAlpha
    property real veilHiAlpha
    property real highlightAlpha
    property real hairlineAlpha

    readonly property color mica: Qt.alpha(surfaceContainerLow, micaAlpha)
    readonly property color glass: Qt.alpha(surfaceContainerHigh, glassAlpha)
    readonly property color thick: Qt.alpha(surfaceContainerHigh, thickAlpha)
    readonly property color veil: Qt.alpha(ink, veilAlpha)
    readonly property color veilHi: Qt.alpha(ink, veilHiAlpha)
    readonly property color highlight: Qt.rgba(1, 1, 1, highlightAlpha)
    readonly property color hairline: Qt.alpha(ink, hairlineAlpha)

    function assign(roles) {
        for (const key in roles) {
            let prop = key.replace(/_([a-z])/g, (m, c) => c.toUpperCase());
            if (/^on[A-Z]/.test(prop))
                prop = prop.toLowerCase();
            if (prop in this)
                this[prop] = roles[key];
        }
    }
}
