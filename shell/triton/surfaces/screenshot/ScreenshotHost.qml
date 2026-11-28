pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.screenshot
import qs.tokens

// The capture tool on every screen, the countdown, and the card afterwards.
// Always dark.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool focused: Hyprland.focusedMonitor === monitor

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            // Opaque all over: its own namespace keeps compositor blur off it.
            WlrLayershell.namespace: "triton-opaque"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: ScreenshotState.ready

            // Windows on this screen, floating ones first, then most recent.
            readonly property var windows: {
                const workspace = monitor?.activeWorkspace;
                return Hyprland.toplevels.values
                    .filter(t => t.workspace === workspace && t.lastIpcObject?.at && !t.lastIpcObject.hidden)
                    .map(t => t.lastIpcObject)
                    .sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
                    .map(w => ({ x: w.at[0] - modelData.x, y: w.at[1] - modelData.y,
                        width: w.size[0], height: w.size[1], title: w.title }));
            }

            onVisibleChanged: {
                if (!visible)
                    return;
                tool.reset();
                tool.forceActiveFocus();
            }

            ThemeScope {
                mode: "dark"
                anchors.fill: parent

                CaptureScreen {
                    id: tool
                    anchors.fill: parent
                    focus: true
                    frozen: ScreenshotState.ready ? ScreenshotState.frozen(window.modelData.name) : ""
                    mode: ScreenshotState.mode
                    windows: window.windows
                    scale0: window.monitor?.scale ?? 1
                    screenName: window.modelData.name
                    delay: ScreenshotState.delay
                    pointer: ScreenshotState.pointer
                    video: ScreenshotState.video
                    audio: ScreenshotState.audio
                    onVideoToggled: ScreenshotState.video = !ScreenshotState.video
                    onAudioPicked: audio => ScreenshotState.audio = audio
                    onModePicked: mode => ScreenshotState.mode = mode
                    onDelayCycled: ScreenshotState.cycleDelay()
                    onPointerToggled: ScreenshotState.pointer = !ScreenshotState.pointer
                    onCancelled: ScreenshotState.cancel()
                    onCaptured: (area, copyOnly) => ScreenshotState.capture({
                            name: window.modelData.name,
                            x: window.modelData.x,
                            y: window.modelData.y,
                            scale: tool.scale0
                        }, area, copyOnly)
                }
            }
        }
    }

    // Window positions only arrive on request.
    Connections {
        target: ScreenshotState
        function onOpenChanged() {
            if (ScreenshotState.open)
                WindowService.refresh();
        }
    }

    // The countdown takes no input, so menus can be opened while it runs.
    PanelWindow {
        id: badge
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        implicitWidth: Metrics.countdownBadge
        implicitHeight: Metrics.countdownBadge + Metrics.hintHeight
        mask: Region {}
        // Gone before the capture: the settle time outlasts the fade.
        visible: countdownPresence.mapped

        // The last second stays up while it fades.
        property int seconds: 0
        Connections {
            target: ScreenshotState
            function onCountdownChanged() {
                if (ScreenshotState.countdown > 0)
                    badge.seconds = ScreenshotState.countdown;
            }
        }

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            Presence {
                id: countdownPresence
                show: ScreenshotState.countdown > 0
                fromScale: Metrics.enterScale
                anchors.fill: parent

                Countdown {
                    anchors.fill: parent
                    seconds: badge.seconds
                }
            }
        }
    }

    PanelWindow {
        id: card
        anchors {
            left: true
            bottom: true
        }
        margins {
            left: Metrics.panelPad
            bottom: Metrics.panelPad
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        implicitWidth: result.implicitWidth
        implicitHeight: result.implicitHeight
        visible: presence.mapped

        // Kept while the card animates away.
        property var shown: null
        Connections {
            target: ScreenshotState
            function onResultChanged() {
                if (ScreenshotState.result)
                    card.shown = ScreenshotState.result;
            }
        }

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            Presence {
                id: presence
                show: ScreenshotState.result !== null
                fromY: Metrics.osdRise
                anchors.fill: parent

                ResultCard {
                    id: result
                    anchors.fill: parent
                    result: card.shown
                    onViewRequested: ScreenshotState.view()
                    onFolderRequested: ScreenshotState.showFolder()
                    onDeleteRequested: ScreenshotState.discard()
                }
            }
        }

        Timer {
            running: ScreenshotState.result !== null && !result.hovered
            interval: Motion.shotCardHold
            onTriggered: ScreenshotState.result = null
        }
    }
}
