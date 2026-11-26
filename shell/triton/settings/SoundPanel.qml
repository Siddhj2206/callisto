pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../components"
import "../services"

// Sound panel: output device volume + input + output device selection.
// Service-backed in production (pipewire); structure follows the QS board's
// sound drill-in rows.

Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }
    readonly property bool hasSink: !!root.sink && !!root.sink.audio
    readonly property bool hasSource: !!root.source && !!root.source.audio
    readonly property string sinkName: hasSink ? (root.sink.description || root.sink.name || "Output") : "No output device"
    readonly property string sourceName: hasSource ? (root.source.description || root.source.name || "Input") : "No input device"

    PanelHeader {
        y: 28
        title: "Sound"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        SectionLabel { label: "Output"; bottomPadding: 8 }

        SettingRow {
            icon: Icons.volumeUp
            title: "Output volume"
            supporting: sinkName
            TritonSlider {
                width: 260
                value: root.hasSink ? root.sink.audio.volume : 0
                onMoved: v => {
                    if (root.hasSink)
                        root.sink.audio.volume = Math.max(0, Math.min(1, v));
                }
            }
        }

        SettingRow {
            icon: Icons.mic
            title: "Input volume"
            supporting: sourceName
            TritonSlider {
                width: 260
                value: root.hasSource ? root.source.audio.volume : 0
                onMoved: v => {
                    if (root.hasSource)
                        root.source.audio.volume = Math.max(0, Math.min(1, v));
                }
            }
        }

        SectionLabel { label: "Devices"; bottomPadding: 8; topPadding: 20 }

        SettingRow {
            icon: Icons.volumeUp
            title: "Speakers"
            supporting: "Built-in audio · active"
        }
        SettingRow {
            icon: Icons.volumeUp
            title: "Headphones"
            supporting: "Not connected"
        }
    }
}
