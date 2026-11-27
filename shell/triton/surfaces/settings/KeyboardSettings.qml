import QtQuick
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    title: "Keyboard"

    readonly property int repeatRate: SettingsService.get("input", "repeatRate", 25)
    readonly property int repeatDelay: SettingsService.get("input", "repeatDelay", 400)

    SettingGroup {
        SettingRow {
            title: "Layout"
            below: ChoiceChips {
                width: parent.width
                // The values are xkb layout names.
                options: [
                    { value: "us", label: "English (US)" },
                    { value: "gb", label: "English (UK)" },
                    { value: "de", label: "German" },
                    { value: "fr", label: "French" },
                    { value: "es", label: "Spanish" },
                    { value: "it", label: "Italian" },
                    { value: "pt", label: "Portuguese" },
                    { value: "ru", label: "Russian" },
                    { value: "jp", label: "Japanese" },
                    { value: "kr", label: "Korean" },
                ]
                current: SettingsService.get("input", "keyboardLayout", "us")
                onChosen: value => SettingsService.set("input", "keyboardLayout", value)
            }
        }
    }

    SettingGroup {
        title: "Typing"

        SettingRow {
            title: "Key repeat"
            subtitle: "A held key types again and again"
            Switch {
                label: "Key repeat"
                checked: SettingsService.get("input", "repeat", true)
                onToggled: on => SettingsService.set("input", "repeat", on)
            }
        }
        SettingRow {
            title: "Repeat rate"
            subtitle: repeatRate + " per second"
            Slider {
                width: Metrics.settingsControl
                label: "Repeat rate"
                // 10 to 50 per second.
                value: (repeatRate - 10) / 40
                onMoved: v => SettingsService.set("input", "repeatRate", Math.round(10 + v * 40))
            }
        }
        SettingRow {
            title: "Delay before repeating"
            subtitle: repeatDelay + " ms"
            Slider {
                width: Metrics.settingsControl
                label: "Delay before repeating"
                // 200 to 600 ms.
                value: (repeatDelay - 200) / 400
                onMoved: v => SettingsService.set("input", "repeatDelay", Math.round(200 + v * 400))
            }
        }
    }
}
