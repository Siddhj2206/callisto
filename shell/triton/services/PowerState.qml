pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Power menu visibility. Opened from the quick settings power button, a
// keybind or the launcher; Escape and click-off cancel.

Singleton {
    property bool open: false
    property string highlight: "" // the action to open on, or "" for the first

    function toggle() {
        highlight = "";
        open = !open;
    }

    // Open with `action` highlighted; it still takes a press to run it.
    function show(action) {
        highlight = action;
        open = true;
    }

    function dismiss() {
        open = false;
        highlight = "";
    }
}
