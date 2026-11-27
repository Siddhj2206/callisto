pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.screenshot
import qs.tokens

// The capture tool with a selection, the result card and the countdown.
// Run: scripts/test-shell.sh --gallery screenshot
Scope {
    Fonts {}

    FloatingWindow {
        title: "Callisto screenshot"
        implicitWidth: 1280
        implicitHeight: 800
        color: "#101014"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            CaptureScreen {
                anchors.fill: parent
                frozen: Qt.resolvedUrl("assets/wallpaper-1646.jpg")
                delay: 3
                pointer: true
                Component.onCompleted: selection = Qt.rect(360, 180, 520, 340)
            }
            ResultCard {
                x: Metrics.panelPad
                y: parent.height - height - Metrics.panelPad
                width: implicitWidth
                height: implicitHeight
                result: ({ path: Qt.resolvedUrl("assets/wallpaper-lock.jpg").toString().replace("file://", ""), width: 700, height: 480, saved: true })
            }
            Countdown {
                x: parent.width - width - Metrics.panelPad
                y: parent.height / 3
                seconds: 3
            }
        }
    }
}
