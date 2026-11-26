pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "services"

// The desktop surface: the wallpaper layer behind everything. One instance
// per screen, background layer, exclusion zero — it never participates in
// layout. The wallpaper path comes from the settings store; changing it in
// the settings app repaints this live, and matugen-derived colors follow
// through the same apply pass.

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    screen: root.screen
    color: Theme.surfaceDim
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "triton-desktop"

    readonly property string wallpaperPath: SettingsService.get("appearance", "wallpaper", "")

    Image {
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
    }
}
