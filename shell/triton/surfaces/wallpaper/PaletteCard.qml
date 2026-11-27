pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// The colors the previewed wallpaper would give the desktop.
Item {
    id: root

    property var palette: null // { dark: {role: "#hex"}, light: {...} }
    property bool light: false
    property bool follows: true // whether the accent comes from the wallpaper

    signal followRequested

    readonly property var roles: ["primary", "secondary", "tertiary", "primary_container", "surface_container_high"]
    readonly property var scheme: palette ? (light ? palette.light : palette.dark) : null

    implicitWidth: Metrics.paletteWidth
    implicitHeight: column.implicitHeight + Metrics.panelPad * 2

    Material {
        anchors.fill: parent
        radius: Metrics.radiusPanelS
    }

    Column {
        id: column
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        AppText {
            role: "title"
            text: "Colors from this picture"
        }
        Row {
            visible: root.scheme !== null
            spacing: Metrics.buttonGap

            Repeater {
                model: root.roles

                WaveShape {
                    required property string modelData
                    width: Metrics.disc
                    height: width
                    color: root.scheme?.[modelData] ?? "transparent"
                }
            }
        }
        AppText {
            width: parent.width
            wrapMode: Text.WordWrap
            role: "bodySmall"
            tone: "onsurfacevariant"
            text: root.scheme === null ? "Reading colors…"
                : root.follows ? "The desktop takes these on when you set it."
                : "Your accent color is fixed, so the desktop keeps its colors."
        }
        Button {
            visible: !root.follows
            variant: "veil"
            text: "Use wallpaper colors"
            onClicked: root.followRequested()
        }
    }
}
