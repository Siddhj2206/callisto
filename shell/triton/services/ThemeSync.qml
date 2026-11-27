import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.tokens

// Follows the user's theme: the tokens settingsd compiles, the day/night flip
// in auto mode, reduce motion, and what the materials need to know to stay
// legible. One per process that draws.
Scope {
    id: root

    readonly property bool solid: SettingsService.material === "solid"

    // The wallpaper's extremes, from a small sample about as smooth as its blur.
    ColorQuantizer {
        id: wallpaper
        source: "file://" + WallpaperState.shown
        depth: 4
        rescaleSize: 64
        onColorsChanged: {
            if (colors.length === 0)
                return;
            const sorted = [...colors].sort((a, b) => Colors.dark.luminance(a.r, a.g, a.b) - Colors.dark.luminance(b.r, b.g, b.b));
            Colors.light.behind = sorted[0];
            Colors.dark.behind = sorted[sorted.length - 1];
        }
    }

    Binding {
        target: Colors.dark
        property: "solid"
        value: root.solid
    }

    Binding {
        target: Colors.light
        property: "solid"
        value: root.solid
    }

    // The engine rewrites the file when accent, contrast or mode change, and
    // the watcher repaints everything in the same frame.
    FileView {
        path: Quickshell.env("HOME") + "/.config/callisto/tokens.json"
        watchChanges: true
        blockLoading: false
        onFileChanged: reload()
        onLoaded: {
            try {
                Theme.applyUserTokens(JSON.parse(text()));
            } catch (e) {
                console.warn("triton: user tokens unparseable, keeping compiled defaults:", e);
            }
        }
    }

    // Auto light/dark: re-resolve on the minute boundary. Cheap, since
    // applyUserTokens only repaints when active_mode flips the palette. Other
    // apps follow through settingsd, which keeps the same schedule.
    Timer {
        interval: 60000
        running: Theme.userTokens !== null
        repeat: true
        onTriggered: Theme.applyUserTokens(Theme.userTokens)
    }

    // An accessibility preference, not a color role, so it is not in the tokens.
    Binding {
        target: Theme
        property: "reduceMotion"
        value: SettingsService.reduceMotion
    }
}
