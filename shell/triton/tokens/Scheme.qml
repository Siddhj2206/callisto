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
    property real backdropAlpha

    // Mica and Glass show the wallpaper only. This is its brightest color
    // under the dark scheme, its darkest under the light one.
    property color behind
    // The "Solid" material setting: nothing is translucent.
    property bool solid: false

    readonly property color mica: Qt.alpha(surfaceContainerLow, solid ? 1 : legible(surfaceContainerLow, micaAlpha))
    readonly property color glass: Qt.alpha(surfaceContainerHigh, solid ? 1 : legible(surfaceContainerHigh, glassAlpha))
    // Thick sees the windows below, so its alpha holds over anything.
    readonly property color thick: Qt.alpha(surfaceContainerHigh, solid ? 1 : thickAlpha)
    readonly property color veil: Qt.alpha(ink, veilAlpha)
    readonly property color veilHi: Qt.alpha(ink, veilHiAlpha)
    readonly property color highlight: Qt.rgba(1, 1, 1, highlightAlpha)
    readonly property color hairline: Qt.alpha(ink, hairlineAlpha)
    // The blue-black laid over the whole screen behind modal surfaces.
    readonly property color backdrop: Qt.rgba(0, 10 / 255, 30 / 255, backdropAlpha)

    // The least opaque a material can be, from its designed alpha up, with
    // secondary text on a veil still at 4.5:1 over what is behind it.
    // scripts/check-contrast.py does the same sum.
    function legible(fill, designed) {
        const text = luminance(onsurfacevariant.r, onsurfacevariant.g, onsurfacevariant.b);
        const mix = (a, b, t) => a * t + b * (1 - t);
        for (let alpha = designed; alpha < 1; alpha += 0.01) {
            const under = luminance(...["r", "g", "b"].map(c => mix(ink[c], mix(fill[c], behind[c], alpha), veilAlpha)));
            if ((Math.max(text, under) + 0.05) / (Math.min(text, under) + 0.05) >= 4.5)
                return alpha;
        }
        return 1;
    }

    function luminance(r, g, b) {
        const linear = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
    }

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
