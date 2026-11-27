import QtQuick
import qs.tokens

// Forces a color scheme on its subtree. Lock, greeter, power, overview and
// screenshot are always dark; everything else inherits the user's mode.
Item {
    property string mode: "follow" // "follow" | "dark" | "light"
    readonly property Scheme themeScheme: mode === "dark" ? Colors.dark
        : mode === "light" ? Colors.light : Colors.current
}
