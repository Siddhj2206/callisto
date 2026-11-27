pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    title: "Sound"

    SettingGroup {
        title: "Output"

        SettingRow {
            glyph: AudioService.muted ? Icons.volumeOff : Icons.volumeUp
            title: "Volume"
            subtitle: !AudioService.available ? "No output device"
                : AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%"
            clickable: AudioService.available
            onClicked: AudioService.toggleMute()
            Slider {
                width: Metrics.settingsControl
                label: "Output volume"
                value: AudioService.volume
                off: AudioService.muted
                onMoved: v => AudioService.setVolume(v)
            }
        }
        Repeater {
            model: AudioService.outputs

            SettingRow {
                required property var modelData
                title: AudioService.name(modelData)
                selected: modelData === AudioService.sink
                subtitle: selected ? "In use" : ""
                glyph: selected ? Icons.checkCircle : Icons.speaker
                clickable: !selected
                onClicked: AudioService.setOutput(modelData)
            }
        }
    }

    SettingGroup {
        title: "Input"

        SettingRow {
            glyph: AudioService.sourceMuted ? Icons.micOff : Icons.mic
            title: "Microphone"
            subtitle: !AudioService.sourceAudio ? "No input device"
                : AudioService.sourceMuted ? "Muted" : Math.round(AudioService.sourceVolume * 100) + "%"
            clickable: AudioService.sourceAudio !== null
            onClicked: AudioService.toggleSourceMute()
            Slider {
                width: Metrics.settingsControl
                label: "Microphone level"
                value: AudioService.sourceVolume
                off: AudioService.sourceMuted
                onMoved: v => AudioService.setSourceVolume(v)
            }
        }
        Repeater {
            model: AudioService.inputs

            SettingRow {
                required property var modelData
                title: AudioService.name(modelData)
                selected: modelData === AudioService.source
                subtitle: selected ? "In use" : ""
                glyph: selected ? Icons.checkCircle : Icons.mic
                clickable: !selected
                onClicked: AudioService.setInput(modelData)
            }
        }
    }
}
