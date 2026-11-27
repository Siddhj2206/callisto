// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import QtQuick
import qs

QtObject {
    // Springs are [stiffness, damping ratio].
    readonly property var spatialFast: [800, 0.6]
    readonly property var spatialDefault: [380, 0.8]
    readonly property var spatialSlow: [200, 0.8]

    property bool reduce: Theme.reduceMotion
    readonly property int fadeFast: reduce ? 120 : 70
    readonly property int fadeDefault: reduce ? 120 : 120
    readonly property int fadeSlow: reduce ? 120 : 180

    readonly property int barRevealDwell: 120
    readonly property int barHideDelay: 600
    readonly property int urgentPeek: 4000
    readonly property int osdHold: 1200
    readonly property int osdAction: 6000
    readonly property int mediaPauseFade: 120000
    readonly property int mediaAnnounce: 2000
    readonly property int toastHold: 6000
    readonly property int powerCountdown: 5000
    readonly property int passwordReveal: 5000
    readonly property int switcherOpenDelay: 120
    readonly property int captureSettle: 150
    readonly property int shotCardHold: 5000
}
