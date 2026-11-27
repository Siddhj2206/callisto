// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import QtQuick
import qs

QtObject {
    id: root

    readonly property Scheme dark: Scheme {
        primary: "#B0C6FF"
        onprimary: "#002D6E"
        primaryContainer: "#00429B"
        onprimarycontainer: "#D9E2FF"
        secondary: "#BFC6DC"
        onsecondary: "#293041"
        secondaryContainer: "#3F4759"
        onsecondarycontainer: "#DBE2F9"
        tertiary: "#FFB59B"
        ontertiary: "#5A1B00"
        tertiaryContainer: "#7C3114"
        ontertiarycontainer: "#FFDBCE"
        error: "#FFB4AB"
        onerror: "#690005"
        errorContainer: "#93000A"
        onerrorcontainer: "#FFDAD6"
        surface: "#111318"
        surfaceContainerLowest: "#0C0E13"
        surfaceContainerLow: "#191C20"
        surfaceContainer: "#1D2024"
        surfaceContainerHigh: "#282A2F"
        surfaceContainerHighest: "#33353A"
        onsurface: "#E2E2E9"
        onsurfacevariant: "#C4C6D0"
        outline: "#8E9099"
        outlineVariant: "#44474F"
        signalWarn: "#FFC857"
        signalInfo: "#6FE0F5"
        micaAlpha: 0.72
        glassAlpha: 0.7
        thickAlpha: 0.88
        veilAlpha: 0.1
        veilHiAlpha: 0.16
        highlightAlpha: 0.14
        hairlineAlpha: 0.12
        backdropAlpha: 0.6
        ink: "#FFFFFF"
    }
    readonly property Scheme light: Scheme {
        primary: "#2F5AC0"
        onprimary: "#FFFFFF"
        primaryContainer: "#D9E2FF"
        onprimarycontainer: "#001945"
        secondary: "#565E71"
        onsecondary: "#FFFFFF"
        secondaryContainer: "#DBE2F9"
        onsecondarycontainer: "#131C2B"
        tertiary: "#8C4A2B"
        ontertiary: "#FFFFFF"
        tertiaryContainer: "#FFDBCE"
        ontertiarycontainer: "#380D00"
        error: "#BA1A1A"
        onerror: "#FFFFFF"
        errorContainer: "#FFDAD6"
        onerrorcontainer: "#410002"
        surface: "#F9F9FF"
        surfaceContainerLowest: "#FFFFFF"
        surfaceContainerLow: "#F3F3FA"
        surfaceContainer: "#EDEDF4"
        surfaceContainerHigh: "#E7E8EE"
        surfaceContainerHighest: "#E2E2E9"
        onsurface: "#191B20"
        onsurfacevariant: "#44474F"
        outline: "#74777F"
        outlineVariant: "#C4C6D0"
        signalWarn: "#FFC857"
        signalInfo: "#6FE0F5"
        micaAlpha: 0.78
        glassAlpha: 0.82
        thickAlpha: 0.9
        veilAlpha: 0.06
        veilHiAlpha: 0.1
        highlightAlpha: 0.6
        hairlineAlpha: 0.12
        backdropAlpha: 0.6
        ink: "#191C20"
    }

    readonly property Scheme current: Theme.activeMode === "light" ? light : dark

    // The engine writes the user's palette to tokens.json; Theme parses it.
    function load() {
        const user = Theme.userTokens?.color;
        if (!user)
            return;
        dark.assign(user.dark);
        light.assign(user.light);
    }

    property Connections follow: Connections {
        target: Theme
        function onUserTokensChanged() { root.load(); }
    }
    Component.onCompleted: load()
}
