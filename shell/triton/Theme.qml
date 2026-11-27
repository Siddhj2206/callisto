// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import QtQuick

QtObject {
    // How strongly a layer of ink shows over a control in each state.
    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.1
    readonly property real statePress: 0.1
    readonly property real stateDrag: 0.16
    readonly property real stateDisabledContent: 0.38
    readonly property real stateDisabledContainer: 0.12
    readonly property real stateDimmed: 0.5

    // The theme engine writes the user's palette to tokens.json. ThemeSync
    // hands it over here and tokens/Colors.qml reads it. It is kept so auto
    // mode can resolve again at dawn and dusk, when the file does not change.
    property var userTokens: null
    property string activeMode: "dark"

    // Follows the setting. tokens/Motion.qml shortens every fade when set.
    property bool reduceMotion: false

    // "auto" is light from 07:00 to 19:00 local time.
    function resolveMode(mode) {
        if (mode !== "auto")
            return mode;
        const hour = new Date().getHours();
        return hour >= 7 && hour < 19 ? "light" : "dark";
    }

    function applyUserTokens(parsed) {
        if (!parsed || !parsed.color)
            return;
        userTokens = parsed;
        activeMode = resolveMode(parsed.active_mode || "dark");
    }
}
