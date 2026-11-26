pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Settings app window visibility. Opened from the launcher, quick settings
// "All settings" button, or `qs ipc call settings toggle`.

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }
}
