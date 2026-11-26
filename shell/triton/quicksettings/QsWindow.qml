pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import ".."
import "../services"

// Quick settings surface: drop-down panel under the right island (Main demo
// placement). Opens from the stat pill; everything inside the panel is mock
// or service-fed depending on what's available — visual structure verified
// in the harness.

PanelWindow {
    id: root

    anchors { top: true; right: true }
    implicitWidth: 400 + 16
    implicitHeight: panel.implicitHeight + 78
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: QuickSettingsState.open

    // Volume is live pipewire state; the slider writes straight to the sink.
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property bool hasSink: !!root.sink && !!root.sink.audio

    // Brightness writes go through brightnessctl (session user has video
    // group access on real hardware; no-op where there is no backlight).
    Process {
        id: brightnessProc
        property real pending: -1
        command: ["brightnessctl", "set", Math.round(pending * 100) + "%"]
    }

    QuickSettingsPanel {
        id: panel
        x: 0
        y: 72 // clear the bar zone
        page: internalPage
        volume: root.hasSink ? root.sink.audio.volume : 0

        property int internalPage: QuickSettingsPanel.Page.Main

        tiles: [
            { glyph: Icons.wifi, fillGlyph: true, label: "Wi-Fi", sublabel: "Not connected", on: false, drillable: true },
            { glyph: Icons.bluetooth, label: "Bluetooth", sublabel: "Off", on: false, drillable: true },
            { glyph: Icons.volumeUp, label: "Sound", sublabel: "Speakers", on: false, drillable: true },
            { glyph: Icons.bedtime, label: "Night light", sublabel: "Off", on: false, drillable: false },
        ]

        onDrillIn: idx => internalPage = QuickSettingsPanel.Page.Wifi
        onBack: internalPage = QuickSettingsPanel.Page.Main
        onVolumeMoved: v => {
            if (root.hasSink)
                root.sink.audio.volume = Math.max(0, Math.min(1, v));
        }
        onBrightnessMoved: v => {
            brightnessProc.pending = v;
            brightnessProc.running = false;
            brightnessProc.running = true;
        }
        onGearClicked: {
            QuickSettingsState.dismiss();
            SettingsAppState.open = true;
        }
        onAllSettings: {
            QuickSettingsState.dismiss();
            SettingsAppState.open = true;
        }
        onPowerClicked: {
            QuickSettingsState.dismiss();
            PowerState.open = true;
        }
    }
}
