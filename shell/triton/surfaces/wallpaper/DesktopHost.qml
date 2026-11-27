pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.surfaces.wallpaper
import qs.tokens

// The desktop behind everything, one per screen.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Colors.current.surfaceContainerLowest
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "triton-desktop"

        Crossfade {
            anchors.fill: parent
            source: "file://" + WallpaperState.shown
        }
    }
}
