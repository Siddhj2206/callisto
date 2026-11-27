import Quickshell
import Quickshell.Io
import QtQuick
import qs

// Follows the user's theme: the tokens settingsd compiles, the day/night flip
// in auto mode, and reduce motion. One per process that draws.
Scope {
    // The engine rewrites the file when accent, contrast or mode change, and
    // the watcher repaints everything in the same frame.
    FileView {
        path: Quickshell.env("HOME") + "/.config/callisto/tokens.json"
        watchChanges: true
        blockLoading: false
        onFileChanged: reload()
        onLoaded: {
            try {
                Theme.reduceMotion = SettingsService.get("shell", "reduceMotion", false);
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
    Connections {
        target: SettingsService
        function onStoreChanged() {
            Theme.reduceMotion = SettingsService.get("shell", "reduceMotion", false);
        }
    }
}
