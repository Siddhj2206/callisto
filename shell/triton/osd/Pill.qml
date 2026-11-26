pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// Leaf component: the glass OSD pill itself, exactly per references/OSD.dc.html.
//
// Board spec (extracted from the board CSS):
//   .osd  height 64, radius 32 (= height/2), gap 14, padding 0 22 0 10,
//         material Glass, fixed content width 330 for slider variants
//   .ico  44x44, radius 22 (circle), white @ 12% — tertiary container +
//         wave clip when the feature is OFF (muted)
//   .trk  170x16, radius 8, white @ 18%; fill primary with radius 8 3 3 8;
//         handle <u> 4px wide, extends 5px above and below the track,
//         centered at the fill edge
//   .val  Jost 26px semibold tabular, min-width 34, right-aligned
//
// State is passed in; this component knows nothing about services.
Item {
    id: root

    // "volume" or "brightness"
    required property string mode
    // 0..1+ (volume may exceed 1 with overdrive)
    required property real level
    required property bool muted
    // total width of the pill (330 per board for slider variants)
    property int pillWidth: 330

    implicitWidth: pillWidth
    implicitHeight: 64

    // The wave clip is only meaningful in the off/muted state; volume in the
    // on state is a circle per the board.
    readonly property bool offState: root.mode === "volume" && root.muted

    // ---- fill geometry (board values, white @ x% over glass = onsurface tint) ----
    readonly property color iconFill: Qt.alpha(Theme.onsurface, 0.12)
    readonly property color trackBase: Qt.alpha(Theme.onsurface, 0.18)

    // Material Symbols ligature steps for volume: off, low, mid, high —
    // volume_mute (speaker only), volume_down (one wave), volume_up (two waves).
    readonly property string iconName: {
        if (root.mode === "brightness") return "brightness_high";
        if (root.muted || root.level <= 0) return "volume_off";
        if (root.level < 0.34) return "volume_mute";
        if (root.level < 0.67) return "volume_down";
        return "volume_up";
    }

    // Track fill fraction: numbers stay meaningful past 100% but the bar saturates.
    readonly property real fillFraction: Math.max(0, Math.min(1, root.level))

    // Board geometry constants (logical px)
    readonly property int padLeft: 10
    readonly property int padRight: 22
    readonly property int gap: 14
    readonly property int icoSize: 44
    readonly property int trackLen: 170
    readonly property int trackH: 16

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.glassBg

        // ---- icon container: circle normally, wave + tertiary container when off ----
        Item {
            id: icoBox
            x: root.padLeft
            width: root.icoSize
            height: root.icoSize
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.offState ? "transparent" : root.iconFill
                visible: !root.offState
            }

            // The wave: identity shape clip, rust container per the board's
            // muted variant ("the circle becomes a wave in rust").
            Shape {
                anchors.fill: parent
                visible: root.offState
                opacity: root.offState ? 1 : 0
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Theme.tertiaryContainer
                    strokeWidth: -1
                    strokeColor: "transparent"
                    PathSvg {
                        path: Theme.wavePath
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.iconName
                font.family: Theme.fontIcons
                font.pixelSize: 24
                color: root.offState ? Theme.ontertiarycontainer : Theme.onsurface

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }
        }

        // ---- track ----
        Item {
            id: track
            x: root.padLeft + root.icoSize + root.gap
            width: root.trackLen
            height: root.trackH
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.trackBase
            }

            Rectangle {
                id: fill
                x: 0
                width: track.width * root.fillFraction
                height: parent.height
                // board: 8 3 3 8 — QML has no per-corner radius; 4 reads as the
                // squarer leading edge without protruding over the rounded base.
                radius: 4
                color: Theme.primary
                visible: width > 0.5

                Behavior on width {
                    NumberAnimation { duration: 100 }
                }
            }

            // handle <u>: 4px wide, extends 5px above/below the track,
            // its center sits 5px past the fill edge per the board CSS.
            Rectangle {
                width: 4
                radius: 2
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height + 10
                x: fill.width + 5 - width / 2
                visible: root.fillFraction > 0

                Behavior on x {
                    NumberAnimation { duration: 100 }
                }
            }
        }

        // ---- value: Jost, tabular, always shown ----
        Text {
            x: track.x + track.width + root.gap
            width: root.pillWidth - x - root.padRight
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            font.family: Theme.fontDisplay
            font.weight: Font.DemiBold
            // board: numbers are Jost 26 semibold; the "Muted" word is 15/600
            font.pixelSize: (root.mode === "volume" && root.muted) ? 15 : 26
            color: Theme.onsurface
            text: {
                if (root.mode === "volume" && root.muted) return "Muted";
                return Math.round(root.level * 100).toString();
            }
        }
    }
}
