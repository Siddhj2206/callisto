pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// The Appearance panel (Settings board, canonical state): wallpaper preview
// with extraction strip, mode segment, accent wave-swatches, contrast
// stops-slider, material picker cards, transparency row. Everything applies
// live — edits go straight to SettingsService, the engine repaints.

Item {
    id: root

    property string mode: SettingsService.get("appearance", "mode", "dark")
    property string accent: SettingsService.get("appearance", "accent", "wallpaper")
    property real contrast: SettingsService.get("appearance", "contrast", 0.0)
    property string material: "mica"
    property string wallpaperPath: SettingsService.get("appearance", "wallpaper", "")
    property bool transparency: true
    property bool tintedSurfaces: false

    // [{name, seed}] swatches rendered as waves
    readonly property var accentSwatches: [
        { name: "Planet", seed: "#2458C8" },
        { name: "Hull", seed: "#1B4560" },
        { name: "Rock", seed: "#4A4D55" },
        { name: "Shadow", seed: "#23262E" },
        { name: "Haze", seed: "#4A3D8F" },
    ]

    signal modePicked(string m)
    signal accentPicked(string a)
    signal contrastMoved(real v)
    signal materialPicked(string m)
    signal transparencyToggled(bool v)
    signal tintedToggled(bool v)
    signal wallpaperBrowse()

    // ---- Header ----
    TritonText {
        x: 32
        y: 36
        text: "Appearance"
        family: TritonText.Family.Display
        weight: TritonText.Weight.Medium
        font.pixelSize: 40
        color: Theme.onsurface
    }
    TritonText {
        x: 32
        y: 84
        text: "Colors come from your wallpaper. Everything below applies live."
        font.pixelSize: 15
        color: Theme.onsurfacevariant
    }

    // ---- Wallpaper preview card ----
    Rectangle {
        x: 32
        y: 124
        width: parent.width - 64
        height: 200
        radius: 24
        color: Theme.surfaceContainerLow
        clip: true

        Image {
            anchors.fill: parent
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.wallpaperBrowse()
        }

        // Mock window silhouette (board shows what theming affects).
        Rectangle {
            x: 0; y: 0
            width: 300
            height: 200
            color: Theme.surface

            Row {
                width: parent.width
                height: parent.height

                Rectangle {
                    width: 90
                    height: parent.height
                    color: Theme.surfaceContainerLow
                }
                Column {
                    x: 12
                    y: 14
                    width: 180
                    spacing: 8

                    Repeater {
                        model: [
                            { w: 108, c: Theme.surfaceContainerHigh },
                            { w: 153, c: Theme.surfaceContainerHigh },
                            { w: 72, c: Theme.primary },
                        ]
                        Rectangle {
                            required property var modelData
                            width: modelData.w
                            height: 8
                            radius: 4
                            color: modelData.c
                        }
                    }
                }
            }
        }

        // Mock shell pill + notification in accent — live preview of tokens.
        Rectangle {
            x: 300 + 12
            y: 12
            width: 200
            height: 20
            radius: 10
            color: Theme.glassBg
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            width: 210
            height: 112
            radius: 20
            color: Theme.glassBg

            Row {
                x: 14
                y: 14
                spacing: 8

                Rectangle { width: 30; height: 30; radius: 15; color: Theme.primary }
                Rectangle { width: 136; height: 30; radius: 15; color: "#29FFFFFF" }
            }
            Column {
                x: 14
                y: 58
                spacing: 8

                Rectangle { width: 128; height: 8; radius: 4; color: "#4DFFFFFF" }
                Rectangle { width: 82; height: 8; radius: 4; color: "#33FFFFFF" }
            }
        }
    }

    // ---- Mode segment: connected group, equal widths, ends rounded ----
    Row {
        x: 32
        y: 334
        spacing: 3

        Repeater {
            model: [
                { id: "dark", glyph: Icons.darkMode, fill: true, label: "Dark" },
                { id: "light", glyph: Icons.lightMode, fill: false, label: "Light" },
                { id: "auto", glyph: Icons.brightnessAuto, fill: false, label: "Auto at sunset" },
            ]

            delegate: Rectangle {
                id: modeDelegate
                required property var modelData
                required property int index
                height: 44
                width: (root.width - 64 - 6) / 3
                radius: index === 0 ? 22 : index === 2 ? 22 : 8
                color: root.mode === modelData.id ? Theme.primary : Theme.surfaceContainerHigh
                property bool active: root.mode === modelData.id

                // Connected-group corners: cover the inner rounding on
                // the touching sides with square patches.
                Rectangle {
                    visible: modeDelegate.index === 0
                    anchors.right: parent.right
                    width: 14
                    height: parent.height
                    color: parent.color
                }
                Rectangle {
                    visible: modeDelegate.index === 2
                    anchors.left: parent.left
                    width: 14
                    height: parent.height
                    color: parent.color
                }

                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 8

                    TritonIcon {
                        glyph: modeDelegate.modelData.glyph
                        fill: modeDelegate.modelData.fill
                        size: 20
                        color: modeDelegate.active ? Theme.onprimary : Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonText {
                        text: modeDelegate.modelData.label
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 14
                        color: modeDelegate.active ? Theme.onprimary : Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.modePicked(modeDelegate.modelData.id);
                        SettingsService.set("appearance", "mode", modeDelegate.modelData.id);
                    }
                }
            }
        }
    }

    // ---- Accent section ----
    TritonText {
        x: 32
        y: 400
        text: "Accent"
        weight: TritonText.Weight.SemiBold
        font.pixelSize: 14
        font.letterSpacing: 0.3
        color: Theme.primary
    }

    Row {
        x: 32
        y: 424
        spacing: 20

        Repeater {
            model: root.accentSwatches

            delegate: Column {
                id: swatchDelegate
                required property var modelData
                required property int index
                property bool active: root.accent === modelData.name.toLowerCase()
                spacing: 8

                Item {
                    width: 64
                    height: 64

                    WaveShape {
                        anchors.fill: parent
                        size: 64
                        color: swatchDelegate.modelData.seed
                    }
                    TritonIcon {
                        visible: swatchDelegate.active
                        anchors.centerIn: parent
                        glyph: Icons.check
                        fill: true
                        size: 28
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.accentPicked(swatchDelegate.modelData.name.toLowerCase());
                            SettingsService.set("appearance", "accent", swatchDelegate.modelData.name.toLowerCase());
                        }
                    }
                }

                TritonText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: swatchDelegate.modelData.name
                    weight: swatchDelegate.active ? TritonText.Weight.SemiBold : TritonText.Weight.Medium
                    font.pixelSize: 13
                    color: swatchDelegate.active ? Theme.onsurface : Theme.onsurfacevariant
                }
            }
        }

        // Custom…
        Column {
            spacing: 8

            Rectangle {
                width: 64
                height: 64
                radius: 32
                color: "transparent"
                border.width: 2
                border.color: Theme.outline

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: Icons.add
                    size: 28
                    color: Theme.onsurfacevariant
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.accentPicked("wallpaper");
                        SettingsService.set("appearance", "accent", "wallpaper");
                    }
                }
            }
            TritonText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Custom"
                weight: TritonText.Weight.Medium
                font.pixelSize: 13
                color: Theme.onsurfacevariant
            }
        }
    }

    // ---- Contrast row ----
    Rectangle {
        x: 32
        y: 536
        width: parent.width - 64
        height: 72
        radius: 16
        color: Theme.surfaceContainer

        Row {
            x: 20
            height: parent.height
            spacing: 16

            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: Theme.secondaryContainer
                anchors.verticalCenter: parent.verticalCenter

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: Icons.contrast
                    size: 22
                    color: Theme.onsecondarycontainer
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                TritonText {
                    text: "Contrast"
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 15
                    color: Theme.onsurface
                }
                TritonText {
                    text: "Standard"
                    font.pixelSize: 13
                    color: Theme.onsurfacevariant
                }
            }
        }

        TritonSlider {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 260
            value: (root.contrast + 1) / 2
            onMoved: v => {
                root.contrastMoved(v * 2 - 1);
                SettingsService.set("appearance", "contrast", v * 2 - 1);
            }
        }
    }

    // ---- Materials ----
    TritonText {
        x: 32
        y: 630
        text: "Materials"
        weight: TritonText.Weight.SemiBold
        font.pixelSize: 14
        font.letterSpacing: 0.3
        color: Theme.primary
    }

    Row {
        x: 32
        y: 654
        spacing: 10

        Repeater {
            model: [
                { id: "solid", name: "Solid", desc: "No blur, lowest power" },
                { id: "mica", name: "Mica", desc: "Wallpaper or solid behind" },
                { id: "glass", name: "Glass", desc: "Blur everything" },
            ]

            delegate: Rectangle {
                id: matDelegate
                required property var modelData
                property bool active: root.material === modelData.id
                width: (parent.parent.width - 64 - 20) / 3
                height: 130
                radius: 20
                color: active ? Theme.secondaryContainer : Theme.surfaceContainer
                border.width: active ? 0 : 1
                border.color: Theme.outlineVariant

                Rectangle {
                    x: 14
                    y: 14
                    width: parent.width - 28
                    height: 64
                    radius: 12
                    color: "#16356F"
                    clip: true

                    Rectangle {
                        x: 18
                        y: 14
                        width: parent.width - 36
                        height: parent.height - 28
                        radius: 8
                        color: matDelegate.modelData.id === "solid" ? "#282A2F"
                             : matDelegate.modelData.id === "mica" ? Theme.micaBg
                             : Theme.glassBg
                    }
                }

                TritonText {
                    x: 14
                    y: 84
                    text: matDelegate.modelData.name
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 15
                    color: Theme.onsurface
                }
                TritonText {
                    x: 14
                    y: 104
                    text: matDelegate.modelData.desc
                    font.pixelSize: 12
                    color: Theme.onsurfacevariant
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.materialPicked(matDelegate.modelData.id);
                        SettingsService.set("appearance", "material", matDelegate.modelData.id);
                    }
                }
            }
        }
    }
}
