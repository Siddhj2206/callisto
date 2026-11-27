pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Appearance"
    subtitle: "Everything here applies as you change it."

    readonly property Scheme scheme: Theming.of(root)
    readonly property string accent: SettingsService.get("appearance", "accent", "wallpaper")
    readonly property bool custom: accent.startsWith("#")

    ClippingRectangle {
        width: parent.width
        height: Metrics.settingsHero
        radius: Metrics.radiusPanelS
        color: root.scheme.surfaceContainerHigh

        Image {
            anchors.fill: parent
            source: "file://" + SettingsService.get("appearance", "wallpaper", "/usr/share/backgrounds/callisto/wallpaper.jpg")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Metrics.settingsContent
        }
        Button {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.rowPad
            variant: "container"
            glyph: Icons.wallpaper
            text: "Change wallpaper"
            // The picker belongs to the shell: the desktop is its preview.
            onClicked: Quickshell.execDetached(["qs", "-c", "triton", "ipc", "call", "wallpaper", "toggle"])
        }
    }

    SettingGroup {
        SettingRow {
            title: "Mode"
            subtitle: "Auto is light from 07:00 to 19:00"
            below: ChoiceChips {
                width: parent.width
                options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }, { value: "auto", label: "Auto" }]
                current: SettingsService.get("appearance", "mode", "dark")
                onChosen: value => SettingsService.set("appearance", "mode", value)
            }
        }
        SettingRow {
            title: "Accent"
            subtitle: root.accent === "wallpaper" ? "Taken from the wallpaper"
                : root.custom ? "Your color, " + root.accent : SettingsCatalog.accents.find(a => a.value === root.accent)?.label ?? ""
            below: Column {
                width: parent.width
                spacing: Metrics.rowGap

                Flow {
                    width: parent.width
                    spacing: Metrics.rowGap

                    Chip {
                        text: "From wallpaper"
                        selected: root.accent === "wallpaper"
                        onClicked: SettingsService.set("appearance", "accent", "wallpaper")
                    }
                    Repeater {
                        model: SettingsCatalog.accents

                        Pressable {
                            id: dot
                            required property var modelData
                            width: Metrics.accentDot
                            height: width
                            radius: width / 2
                            fill: modelData.seed
                            ink: root.scheme.onsurface
                            label: modelData.label + " accent"
                            onClicked: SettingsService.set("appearance", "accent", modelData.value)

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.width: root.accent === dot.modelData.value ? Metrics.focusRing : 1
                                border.color: root.accent === dot.modelData.value ? root.scheme.onsurface : root.scheme.outlineVariant
                            }
                        }
                    }
                }
                TextField {
                    width: Math.min(parent.width, Metrics.settingsControl)
                    placeholder: "Or a color: #RRGGBB, then Enter"
                    text: root.custom ? root.accent : ""
                    onAccepted: {
                        if (/^#[0-9A-Fa-f]{6}$/.test(text))
                            SettingsService.set("appearance", "accent", text.toUpperCase());
                    }
                }
            }
        }
        SettingRow {
            title: "Contrast"
            subtitle: "Stronger text and edges"
            below: ChoiceChips {
                width: parent.width
                options: [{ value: 0, label: "Standard" }, { value: 0.5, label: "Medium" }, { value: 1, label: "High" }]
                current: SettingsService.get("appearance", "contrast", 0)
                onChosen: value => SettingsService.set("appearance", "contrast", value)
            }
        }
    }

    SettingGroup {
        title: "Materials"

        SettingRow {
            title: "Surfaces"
            below: Row {
                width: parent.width
                spacing: Metrics.rowGap

                Repeater {
                    id: choices
                    model: [
                        { value: "solid", title: "Solid", caption: "No blur or shadows. Lightest on the graphics" },
                        { value: "mica", title: "Mica", caption: "Tinted by the wallpaper behind" },
                        { value: "glass", title: "Glass", caption: "Clearer, shows more through" },
                    ]

                    OptionCard {
                        id: card
                        required property var modelData
                        width: (parent.width - parent.spacing * (choices.count - 1)) / choices.count
                        title: modelData.title
                        caption: modelData.caption
                        selected: SettingsService.get("appearance", "material", "mica") === modelData.value
                        onClicked: SettingsService.set("appearance", "material", modelData.value)

                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.listOuter
                            color: root.scheme.primaryContainer

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Metrics.rowGap
                                radius: Metrics.listInner
                                color: card.modelData.value === "solid" ? root.scheme.surfaceContainerHigh
                                    : card.modelData.value === "mica" ? root.scheme.mica : root.scheme.veilHi
                            }
                        }
                    }
                }
            }
        }
    }

    SettingGroup {
        title: "Motion"

        SettingRow {
            glyph: Icons.animation
            title: "Reduce motion"
            subtitle: "Short fades instead of movement"
            Switch {
                label: "Reduce motion"
                checked: SettingsService.get("shell", "reduceMotion", false)
                onToggled: on => SettingsService.set("shell", "reduceMotion", on)
            }
        }
    }
}
