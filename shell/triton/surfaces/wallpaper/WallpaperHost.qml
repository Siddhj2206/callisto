import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.services
import qs.surfaces.wallpaper
import qs.tokens

// The picker on the focused monitor. Nothing is dimmed: the desktop behind it
// is the preview.
OverlayWindow {
    id: root

    open: WallpaperState.open
    presence: motion
    onDismissed: WallpaperState.close()
    onOpening: {
        dock.reveal();
        dock.forceActiveFocus();
    }

    Presence {
        id: motion
        show: root.open
        anchors.fill: parent

        PaletteCard {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Metrics.panelPad
            palette: WallpaperState.palette
            light: Theme.activeMode === "light"
            follows: SettingsService.accent === "wallpaper"
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
                onLockScreen: SettingsService.wallpaperOnLock
                onBrowsed: path => WallpaperState.tryOn(path)
                onChosen: path => WallpaperState.apply(path)
                onFolderRequested: WallpaperState.openFolder()
                onLockToggled: on => SettingsService.set("appearance", "wallpaperOnLock", on)
                onClosed: WallpaperState.close()
            }
        }
    }
}
