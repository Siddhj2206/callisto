pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// Tiles, sliders, and the way into Settings and the power menu. A control the
// machine has no hardware for is left out.
Column {
    id: root

    // [{ key, glyph, title, subtitle, on, drillable }]
    property var tiles: []
    property bool hasBrightness: true
    property real brightness: 0
    property bool hasVolume: true
    property real volume: 0
    property bool muted: false
    property var media: null // the player, if something is playing

    signal tileToggled(string key)
    signal tileDrilled(string key)
    signal brightnessMoved(real value)
    signal volumeMoved(real value)
    signal muteToggled
    signal mediaToggled
    signal mediaNextRequested
    signal mediaPreviousRequested
    signal mediaRequested
    signal settingsRequested
    signal powerRequested

    spacing: Metrics.panelGap

    component SliderRow: Item {
        id: sliderRow
        property string glyph: ""
        property string label: ""
        property alias value: slider.value
        property bool toggles: false
        signal moved(real value)
        signal iconClicked

        width: parent.width
        implicitHeight: slider.implicitHeight

        IconButton {
            id: lead
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.control
            glyph: sliderRow.glyph
            label: sliderRow.label
            interactive: sliderRow.toggles
            onClicked: sliderRow.iconClicked()
        }
        Slider {
            id: slider
            anchors.left: lead.right
            anchors.leftMargin: Metrics.tileGap
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            label: sliderRow.label
            onMoved: v => sliderRow.moved(v)
        }
    }

    PageHeader {
        width: parent.width
        title: "Quick settings"

        IconButton {
            variant: "veil"
            size: Metrics.control
            glyph: Icons.settings
            label: "Settings"
            onClicked: root.settingsRequested()
        }
    }

    Grid {
        id: grid
        width: parent.width
        columns: 2
        spacing: Metrics.tileGap

        // Counted, not bound to the array, so tiles persist and can animate.
        Repeater {
            model: root.tiles.length

            Tile {
                required property int index
                readonly property var entry: root.tiles[index]

                width: (grid.width - grid.spacing) / 2
                glyph: entry.glyph
                title: entry.title
                subtitle: entry.subtitle
                checked: entry.on
                drillable: entry.drillable
                onToggled: root.tileToggled(entry.key)
                onDrilled: root.tileDrilled(entry.key)
            }
        }
    }

    Column {
        width: parent.width
        spacing: Metrics.tileGap
        visible: root.hasBrightness || root.hasVolume

        SliderRow {
            visible: root.hasBrightness
            glyph: Icons.brightness7
            label: "Brightness"
            value: root.brightness
            onMoved: v => root.brightnessMoved(v)
        }
        SliderRow {
            visible: root.hasVolume
            glyph: Icons.volume(root.volume, root.muted)
            label: "Volume"
            value: root.muted ? 0 : root.volume
            toggles: true
            onMoved: v => root.volumeMoved(v)
            onIconClicked: root.muteToggled()
        }
    }

    Rectangle {
        visible: root.media !== null
        width: parent.width
        height: pill.implicitHeight + Metrics.tileGap * 2
        radius: height / 2
        color: Theming.of(root).veil

        MediaPill {
            id: pill
            x: Metrics.tileGap
            anchors.verticalCenter: parent.verticalCenter
            player: root.media
            wide: true
            onToggleRequested: root.mediaToggled()
            onNextRequested: root.mediaNextRequested()
            onPreviousRequested: root.mediaPreviousRequested()
            onOpened: root.mediaRequested()
        }
    }

    Row {
        width: parent.width
        spacing: Metrics.tileGap

        Button {
            width: parent.width - power.width - parent.spacing
            variant: "container"
            glyph: Icons.tune
            text: "All settings"
            onClicked: root.settingsRequested()
        }
        IconButton {
            id: power
            variant: "veil"
            size: Metrics.buttonHeight
            glyph: Icons.powerSettingsNew
            label: "Power"
            onClicked: root.powerRequested()
        }
    }
}
