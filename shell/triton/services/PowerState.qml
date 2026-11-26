pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Power menu visibility. Opened from the quick settings power button or a
// keybind; Escape and click-off cancel.

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }

    function dismiss() {
        open = false;
    }
}
