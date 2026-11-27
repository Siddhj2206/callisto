pragma Singleton

import Quickshell
import QtQuick

// Settings is its own program (settings-app.qml), so that nothing it does can
// take the bar or the lock screen with it. This opens it, or brings it forward.
Singleton {
    // `page` is a page name from SettingsCatalog; without one, the last one.
    function show(page) {
        Quickshell.execDetached(["callisto-settings", page ?? ""]);
    }
}
