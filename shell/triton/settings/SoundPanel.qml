pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// Sound panel: output device volume + input + output device selection.
// Service-backed in production (pipewire); structure follows the QS board's
// sound drill-in rows.

Item {
    id: root

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
            supporting: "Speakers — built-in audio"
            TritonSlider {
                width: 260
                value: 0.42
            }
        }

        SettingRow {
            icon: Icons.mic
            title: "Input volume"
            supporting: "Internal microphone"
            TritonSlider {
                width: 260
                value: 0.7
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
