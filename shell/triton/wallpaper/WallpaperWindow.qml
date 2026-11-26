pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../services"
import ".."

// The wallpaper picker (Wallpaper board): a full-screen surface over the real
// desktop — the preview IS the desktop. Preview pill top-left, Colors card
// top-right, thick glass dock at bottom with collection tabs, applying-to
// segment, and wallpaper thumbnails. Keyboard-driven: ← → browse, Enter set,
// Esc revert. Clicking works everywhere the keys do.

PanelWindow {
    id: root

    visible: WallpaperState.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "triton-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // The wallpaper set. Orbit is the shipped Callisto render; the generative
    // entries are authored scenes drawn in QML — no image files needed, and
    // matugen extracts their dominant tones from the rasterized preview.
    readonly property var wallpapers: [
        { name: "Orbit", kind: "image", path: Qt.resolvedUrl("../board-wallpaper-1646.jpg").toString().replace("file://", "") },
        { name: "Nebula", kind: "nebula" },
        { name: "Dune", kind: "dune" },
        { name: "Ice", kind: "ice" },
        { name: "Dusk", kind: "dusk" },
        { name: "Planet", kind: "planet" },
        { name: "Paper", kind: "paper" },
    ]

    property int selected: 0
    property int applied: 0

    // ---- preview state: what the desktop shows right now ----
    // The desktop surface reads the store; previewing writes nothing — it
    // overrides the Desktop layer directly through WallpaperState.preview.
    // Enter commits through SettingsService; Esc restores.

    function preview() {
        // Live preview: the desktop layer follows this path immediately.
        const w = wallpapers[selected];
        if (w.kind === "image")
            WallpaperState.previewPath = w.path;
        else
            WallpaperState.previewKind = w.kind;
    }

    function commit() {
        const w = wallpapers[selected];
        if (w.kind === "image") {
            SettingsService.set("appearance", "wallpaper", w.path);
        } else {
            SettingsService.set("appearance", "wallpaperKind", w.kind);
        }
        applied = selected;
        WallpaperState.close(false);
    }

    onVisibleChanged: {
        if (visible) {
            // Opening selects the currently-applied wallpaper.
            selected = applied;
            preview();
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                WallpaperState.close(true);
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                root.selected = Math.max(0, root.selected - 1);
                root.preview();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.selected = Math.min(root.wallpapers.length - 1, root.selected + 1);
                root.preview();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.commit();
                event.accepted = true;
            }
        }
    }

    // ---- Preview pill (top-left): glass, h48 r24 ----
    Rectangle {
        x: 40
        y: 40
        height: 48
        width: previewRow.implicitWidth + 40
        radius: 24
        color: Theme.glassBg

        Row {
            id: previewRow
            x: 20
            height: parent.height
            spacing: 10

            TritonIcon {
                glyph: Icons.visibility
                size: 20
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
            TritonText {
                text: "Previewing on your real desktop. Esc puts the old one back."
                font.pixelSize: 14
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- Colors card (top-right): glass w370 r32 ----
    ColorsCard {
        anchors.right: parent.right
        anchors.rightMargin: 40
        y: 40
    }

    // ---- The dock (bottom): thick glass, r36 ----
    WallpaperDock {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.bottomMargin: 24
        wallpapers: root.wallpapers
        selected: root.selected
        applied: root.applied
        onSelected: idx => {
            root.selected = idx;
            root.preview();
        }
        onCommitted: idx => {
            root.selected = idx;
            root.commit();
        }
    }
}
