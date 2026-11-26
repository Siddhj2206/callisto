pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "services"
import "wallpaper"

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
    color: Theme.surfaceContainerLowest
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "triton-desktop"

    readonly property string storeWallpaper: SettingsService.get("appearance", "wallpaper", "/usr/share/backgrounds/callisto/wallpaper.jpg")
    // While the picker previews, the preview channel wins.
    readonly property string wallpaperPath: WallpaperState.previewPath !== "" ? WallpaperState.previewPath : storeWallpaper

    Image {
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
    }

    // Generative wallpapers: the same authored scenes the picker's thumbnails
    // render, full-screen. Preview kind wins over everything while picking.
    readonly property string activeKind: WallpaperState.previewKind !== ""
        ? WallpaperState.previewKind
        : SettingsService.get("appearance", "wallpaperKind", "")

    Loader {
        anchors.fill: parent
        active: root.activeKind !== "" && root.activeKind !== "image"
        sourceComponent: generativeScene
    }

    Component {
        id: generativeScene
        WallpaperScene {
            anchors.fill: parent
            kind: root.activeKind
        }
    }
}
