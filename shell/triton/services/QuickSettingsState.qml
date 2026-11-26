pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Quick settings visibility, opened from the bar's stat pill (volume icon)
// or a keybind. Modal singleton like the launcher.

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }

    function dismiss() {
        open = false;
    }
}
