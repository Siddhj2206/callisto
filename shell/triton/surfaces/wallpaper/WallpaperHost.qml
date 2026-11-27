import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs
import qs.foundations
import qs.services
import qs.surfaces.wallpaper
import qs.tokens

// The picker on the focused monitor. Nothing is dimmed: the desktop behind it
// is the preview.
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WallpaperState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: presence.mapped
    mask: WallpaperState.open ? null : nothing

    Region { id: nothing }

    readonly property bool open: WallpaperState.open
    onOpenChanged: {
        if (!open)
            return;
        if (!presence.mapped) {
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                root.screen = focused;
        }
        dock.reveal();
        dock.forceActiveFocus();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: WallpaperState.close()
    }

    Presence {
        id: presence
        show: root.open
        anchors.fill: parent

        PaletteCard {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Metrics.panelPad
            palette: WallpaperState.palette
            light: Theme.activeMode === "light"
            follows: SettingsService.get("appearance", "accent", "wallpaper") === "wallpaper"
            onFollowRequested: SettingsService.set("appearance", "accent", "wallpaper")
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.panelPad
            height: dock.implicitHeight

            Material {
                anchors.fill: parent
                kind: "thick"
                radius: Metrics.radiusPanelM
            }
            MouseArea {
                anchors.fill: parent
            }

            WallpaperDock {
                id: dock
                anchors.fill: parent
                focus: true
                items: WallpaperState.items
                // The list arrives after the picker opens.
                onItemsChanged: reveal()
                current: WallpaperState.committed
                onLockScreen: SettingsService.get("appearance", "wallpaperOnLock", true)
                onBrowsed: path => WallpaperState.tryOn(path)
                onChosen: path => WallpaperState.apply(path)
                onFolderRequested: WallpaperState.openFolder()
                onLockToggled: on => SettingsService.set("appearance", "wallpaperOnLock", on)
                onClosed: WallpaperState.close()
            }
        }
    }
}
