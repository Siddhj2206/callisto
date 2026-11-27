pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Settings app window visibility. Opened from the launcher, quick settings
// "All settings" button, or `qs ipc call settings toggle`.

Singleton {
    property bool open: false
    property int panel: 7 // sidebar index; 7 is Appearance

    // Opens on a given page, or on the last one.
    function show(index) {
        if (index !== undefined)
            panel = index;
        open = true;
    }

    function toggle() {
        open = !open;
    }
}
