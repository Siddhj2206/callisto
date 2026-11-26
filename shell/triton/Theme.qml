// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import QtQuick

QtObject {
    // ---- Identity ----
    readonly property string tokenVersion: "0.1.0"

    // ---- Color: dark scheme (verbatim from tokens.json) ----
    property color primary: "#B0C6FF"
    property color onprimary: "#002D6E"
    property color primaryContainer: "#00429B"
    property color primary_container: "#00429B"
    property color onprimarycontainer: "#D9E2FF"
    property color secondary: "#BFC6DC"
    property color onsecondary: "#293041"
    property color secondaryContainer: "#3F4759"
    property color secondary_container: "#3F4759"
    property color onsecondarycontainer: "#DBE2F9"
    property color tertiary: "#FFB59B"
    property color ontertiary: "#5A1B00"
    property color tertiaryContainer: "#7C3114"
    property color tertiary_container: "#7C3114"
    property color ontertiarycontainer: "#FFDBCE"
    property color error: "#FFB4AB"
    property color onerror: "#690005"
    property color errorContainer: "#93000A"
    property color error_container: "#93000A"
    property color onerrorcontainer: "#FFDAD6"
    property color surface: "#111318"
    property color surfaceContainerLowest: "#0C0E13"
    property color surface_container_lowest: "#0C0E13"
    property color surfaceContainerLow: "#191C20"
    property color surface_container_low: "#191C20"
    property color surfaceContainer: "#1D2024"
    property color surface_container: "#1D2024"
    property color surfaceContainerHigh: "#282A2F"
    property color surface_container_high: "#282A2F"
    property color surfaceContainerHighest: "#33353A"
    property color surface_container_highest: "#33353A"
    property color onsurface: "#E2E2E9"
    property color onsurfacevariant: "#C4C6D0"
    property color outline: "#8E9099"
    property color outlineVariant: "#44474F"
    property color outline_variant: "#44474F"
    property color signalWarn: "#FFC857"
    property color signal_warn: "#FFC857"
    property color signalInfo: "#6FE0F5"
    property color signal_info: "#6FE0F5"

    // ---- Materials (fill color pre-composited with alpha) ----
    readonly property color glassBg: "#B2282A2F"
    readonly property real glassBlur: 32
    readonly property color micaBg: "#B8191C20"
    readonly property real micaBlur: 48
    readonly property color thickGlassBg: "#E0282A2F"
    readonly property real thickGlassBlur: 40
    readonly property color veil: "#14FFFFFF"
    readonly property color veilBright: "#1AFFFFFF"

    // ---- State layers ----
    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.1
    readonly property real statePress: 0.1
    readonly property real stateDrag: 0.16
    readonly property real stateDisabledcontent: 0.38
    readonly property real stateDisabledcontainer: 0.12

    // ---- Shape (logical px) ----
    readonly property real radiusTiled: 0
    readonly property real radiusXs: 8
    readonly property real radiusSm: 12
    readonly property real radiusMd: 16
    readonly property real radiusLg: 20
    readonly property real radiusXl: 28
    readonly property real radiusFull: 9999
    readonly property real radiusFloating: 28

    // ---- Spacing scale (index into the scale) ----
    readonly property var space: [4, 8, 12, 16, 20, 24, 32, 40, 48, 56]

    // ---- Typography ----
    readonly property string fontDisplay: "Jost"
    readonly property string fontUi: "Google Sans Flex"
    readonly property string fontUiFallback: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontIcons: "Material Symbols Rounded"

    // ---- Motion: [stiffness, damping_ratio] spring pairs ----
    readonly property var motionSpatialFast: [800, 0.6]
    readonly property var motionSpatialDefault: [380, 0.8]
    readonly property var motionSpatialSlow: [200, 0.8]
    readonly property var motionEffectsFast: [3800, 1.0]
    readonly property var motionEffectsDefault: [1600, 1.0]
    readonly property var motionEffectsSlow: [800, 1.0]

    // ---- Sizes ----
    readonly property real barHeight: 56

    // ---- Identity: the Triton wave ----
    readonly property string waveViewBox: "0 0 100 100"
    readonly property int waveLobes: 9
    readonly property string wavePath: "M50.00,9.80 L51.40,9.98 L52.76,10.51 L54.06,11.33 L55.29,12.38 L56.42,13.56 L57.49,14.78 L58.50,15.92 L59.48,16.92 L60.49,17.71 L61.56,18.24 L62.72,18.52 L64.00,18.56 L65.40,18.44 L66.91,18.20 L68.50,17.96 L70.13,17.78 L71.74,17.77 L73.27,17.97 L74.65,18.45 L75.84,19.21 L76.79,20.24 L77.50,21.52 L77.97,22.99 L78.23,24.58 L78.34,26.22 L78.38,27.83 L78.41,29.36 L78.53,30.76 L78.80,32.01 L79.27,33.10 L79.98,34.06 L80.93,34.92 L82.08,35.72 L83.39,36.51 L84.77,37.35 L86.13,38.26 L87.37,39.28 L88.41,40.42 L89.17,41.67 L89.59,43.02 L89.65,44.43 L89.37,45.86 L88.79,47.29 L87.97,48.67 L87.00,50.00 L85.99,51.26 L85.03,52.45 L84.22,53.60 L83.63,54.73 L83.29,55.87 L83.21,57.06 L83.39,58.32 L83.76,59.68 L84.25,61.13 L84.77,62.65 L85.22,64.23 L85.52,65.81 L85.58,67.35 L85.36,68.80 L84.81,70.10 L83.96,71.22 L82.82,72.14 L81.46,72.85 L79.94,73.39 L78.34,73.78 L76.76,74.10 L75.26,74.40 L73.90,74.75 L72.72,75.23 L71.73,75.89 L70.91,76.76 L70.23,77.84 L69.64,79.12 L69.08,80.54 L68.50,82.04 L67.83,83.54 L67.04,84.95 L66.10,86.17 L65.00,87.13 L63.75,87.78 L62.37,88.08 L60.91,88.06 L59.41,87.73 L57.90,87.16 L56.42,86.44 L55.01,85.66 L53.67,84.93 L52.40,84.33 L51.19,83.94 L50.00,83.80 L48.81,83.94 L47.60,84.33 L46.33,84.93 L44.99,85.66 L43.58,86.44 L42.10,87.16 L40.59,87.73 L39.09,88.06 L37.63,88.08 L36.25,87.78 L35.00,87.13 L33.90,86.17 L32.96,84.95 L32.17,83.54 L31.50,82.04 L30.92,80.54 L30.36,79.12 L29.77,77.84 L29.09,76.76 L28.27,75.89 L27.28,75.23 L26.10,74.75 L24.74,74.40 L23.24,74.10 L21.66,73.78 L20.06,73.39 L18.54,72.85 L17.18,72.14 L16.04,71.22 L15.19,70.10 L14.64,68.80 L14.42,67.35 L14.48,65.81 L14.78,64.23 L15.23,62.65 L15.75,61.13 L16.24,59.68 L16.61,58.32 L16.79,57.06 L16.71,55.87 L16.37,54.73 L15.78,53.60 L14.97,52.45 L14.01,51.26 L13.00,50.00 L12.03,48.67 L11.21,47.29 L10.63,45.86 L10.35,44.43 L10.41,43.02 L10.83,41.67 L11.59,40.42 L12.63,39.28 L13.87,38.26 L15.23,37.35 L16.61,36.51 L17.92,35.72 L19.07,34.92 L20.02,34.06 L20.73,33.10 L21.20,32.01 L21.47,30.76 L21.59,29.36 L21.62,27.83 L21.66,26.22 L21.77,24.58 L22.03,22.99 L22.50,21.52 L23.21,20.24 L24.16,19.21 L25.35,18.45 L26.73,17.97 L28.26,17.77 L29.87,17.78 L31.50,17.96 L33.09,18.20 L34.60,18.44 L36.00,18.56 L37.28,18.52 L38.44,18.24 L39.51,17.71 L40.52,16.92 L41.50,15.92 L42.51,14.78 L43.58,13.56 L44.71,12.38 L45.94,11.33 L47.24,10.51 L48.60,9.98Z"

    // ---- Live re-application (the no-dotfiles contract) ----
    // The theme engine (callisto-apply) writes user-resolved tokens to
    // ~/.config/callisto/tokens.json; shell.qml watches that file and
    // calls this with its parsed content. Property naming mirrors the
    // snake_case -> camelCase rules above, including the on* lowering.
    function applyUserTokens(parsed) {
        const dark = parsed && parsed.color && parsed.color.dark;
        if (!dark)
            return;
        for (const key of Object.keys(dark)) {
            const value = dark[key];
            if (typeof value !== "string" || !/^#[0-9A-Fa-f]{6}$/.test(value))
                continue;
            let prop = key.replace(/_([a-z])/g, (m, c) => c.toUpperCase());
            if (/^on[A-Z]/.test(prop))
                prop = prop.toLowerCase();
            if (prop in this)
                this[prop] = value.toUpperCase();
            if (key in this && key !== prop)
                this[key] = value.toUpperCase();
        }
    }
}
