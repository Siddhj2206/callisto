import QtQuick
import QtQuick.Effects

// A blurred, darkened copy of `source`. Needs qml6-module-qtquick-effects, so
// load it through a Loader: without the module only the blur is lost.
MultiEffect {
    blurEnabled: true
    blur: 0.6
    blurMax: 32
    brightness: -0.12
    saturation: 0.1
    // The blur must not fade out at the screen's edges.
    autoPaddingEnabled: false
}
