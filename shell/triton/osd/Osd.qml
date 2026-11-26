pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// On-screen display pill (OSD board): h64 r32 Glass, padding 0/22/0/10,
// 14px gaps, bottom-center 48px above the screen edge. One at a time — a new
// OSD morphs the old in place; the caller replaces state, never stacks.
//
// Icon container: 44px white/.12 circle at rest — becoming a wave in
// tertiary/error-container when the state is off, muted or alerting (the
// board's one rule: "when something turns off, the circle becomes a wave").
//
// This is a leaf: the controller decides variant and values. Pointer events
// pass through by design (the board forbids the OSD taking input) — except
// battery-low's Saver action, the one interactive variant.

Rectangle {
    id: root

    enum Variant { Volume, Brightness, Muted, MicOff, Keyboard, Workspace, Track, BatteryLow }

    property int variant: Osd.Variant.Volume

    // Numeric variants.
    property real value: 0.62 // 0..1
    property string icon: Icons.volumeUp
    property bool fillIcon: true

    // Text variants.
    property string text: ""
    property string subtext: ""

    // Track variant.
    property string trackTitle: ""
    property string trackArtist: ""

    // Battery low.
    property string batteryPercentText: ""
    property string batteryTimeText: ""

    signal actionClicked

    readonly property bool isOff: root.variant === Osd.Variant.Muted || root.variant === Osd.Variant.MicOff || root.variant === Osd.Variant.BatteryLow
    readonly property color waveColor: root.variant === Osd.Variant.Muted ? Theme.tertiaryContainer
                                     : Theme.errorContainer
    readonly property color waveGlyphColor: root.variant === Osd.Variant.Muted ? Theme.ontertiarycontainer
                                          : Theme.onerrorcontainer

    readonly property bool isNumeric: root.variant === Osd.Variant.Volume || root.variant === Osd.Variant.Brightness

    // The wave glyph can overhang the pill when the Shape scales beyond its
    // item — content must never escape the pill silhouette.
    clip: true

    height: 64
    radius: 32
    color: Theme.glassBg
    width: root.variant === Osd.Variant.Volume || root.variant === Osd.Variant.Muted || root.variant === Osd.Variant.Brightness ? 330
         : root.variant === Osd.Variant.MicOff ? 270
         : root.variant === Osd.Variant.Track || root.variant === Osd.Variant.BatteryLow ? 346
         : implicitWidth

    implicitWidth: contentRow.implicitWidth + (root.variant === Osd.Variant.Keyboard ? 28 : 32)

    Row {
        id: contentRow
        x: root.variant === Osd.Variant.Keyboard ? 14 : 10
        height: parent.height
        spacing: root.variant === Osd.Variant.Track || root.variant === Osd.Variant.BatteryLow ? 12
               : root.variant === Osd.Variant.Workspace ? 10 : 14

        // Icon container: circle or wave-per-state.
        Item {
            width: 44
            height: 44
            anchors.verticalCenter: parent.verticalCenter
            visible: root.variant !== Osd.Variant.Workspace

            Rectangle {
                visible: !root.isOff && root.variant !== Osd.Variant.Track
                anchors.fill: parent
                radius: 22
                color: "#1FFFFFFF" // white .12

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: root.icon
                    fill: root.fillIcon
                    size: 24
                    color: Theme.onsurface
                }
            }

            WaveShape {
                visible: root.isOff
                anchors.fill: parent
                size: 44
                color: root.waveColor
                glyph: root.icon
                fillGlyph: true
                glyphColor: root.waveGlyphColor
                glyphSize: 24
            }

            // Track variant: album art in a wave (identity, not an icon).
            // Art arrives with the media service; the shape is what matters.
            WaveShape {
                visible: root.variant === Osd.Variant.Track
                anchors.fill: parent
                size: 44
                color: Theme.primary
            }
        }

        // Numeric variants: track + handle + value.
        Item {
            visible: root.isNumeric
            width: 170
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#2EFFFFFF" // white .18
            }
            Rectangle {
                width: parent.width * root.value
                height: parent.height
                radius: 8
                color: Theme.primary
                // asymmetric radii (8px 3px 3px 8px) are below the pixel
                // floor at 16px height — visually negligible, keep r8.
            }
            // Handle: 4px wide, protrudes ±5px vertically.
            Rectangle {
                visible: root.value > 0
                x: parent.width * root.value + 5 - width
                width: 4
                height: parent.height + 10
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: Theme.primary
            }
        }

        TritonText {
            visible: root.isNumeric
            text: Math.round(root.value * 100)
            family: TritonText.Family.Display
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 26
            color: Theme.onsurface
            boxHeight: 64
        }

        // Muted: text instead of value.
        TritonText {
            visible: root.variant === Osd.Variant.Muted
            text: "Muted"
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 15
            color: Theme.onsurface
            boxHeight: 64
        }

        // Mic off: persistent label.
        TritonText {
            visible: root.variant === Osd.Variant.MicOff
            text: "Microphone off"
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 16
            color: Theme.onsurface
            boxHeight: 64
        }

        // Keyboard layout: Jost letters over language.
        Column {
            visible: root.variant === Osd.Variant.Keyboard
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            TritonText {
                text: root.text
                family: TritonText.Family.Display
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 24
                color: Theme.onsurface
            }
            TritonText {
                text: root.subtext
                font.pixelSize: 12
                color: Theme.onsurfacevariant
            }
        }

        // Track / battery: title + subtitle pair.
        Column {
            visible: root.variant === Osd.Variant.Track || root.variant === Osd.Variant.BatteryLow
            anchors.verticalCenter: parent.verticalCenter
            width: root.variant === Osd.Variant.BatteryLow ? 150 : 180

            TritonText {
                text: root.variant === Osd.Variant.Track ? root.trackTitle : root.batteryPercentText
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 15
                color: Theme.onsurface
                elide: Text.ElideRight
                width: parent.width
            }
            TritonText {
                text: root.variant === Osd.Variant.Track ? root.trackArtist : root.batteryTimeText
                font.pixelSize: 12
                color: Theme.onsurfacevariant
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Track: filled skip_next in primary.
        TritonIcon {
            visible: root.variant === Osd.Variant.Track
            anchors.verticalCenter: parent.verticalCenter
            glyph: Icons.skipNext
            fill: true
            size: 24
            color: Theme.primary
        }

        // Battery low: the only OSD action — Saver pill.
        Rectangle {
            visible: root.variant === Osd.Variant.BatteryLow
            width: saverText.implicitWidth + 28
            height: 34
            radius: 17
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.primary

            TritonText {
                id: saverText
                anchors.centerIn: parent
                text: "Saver"
                weight: TritonText.Weight.SemiBold
                font.pixelSize: 13
                color: Theme.onprimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }

    // Everything except the Saver action passes pointer events through.
    MouseArea {
        anchors.fill: parent
        enabled: root.variant === Osd.Variant.BatteryLow
        propagateComposedEvents: true
        onPressed: mouse => mouse.accepted = false
    }
}
