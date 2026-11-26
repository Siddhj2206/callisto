pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Clipboard panel visibility. Super+V opens it (keybind lives in the
// compositor config); selecting an entry pastes and closes.

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }

    function dismiss() {
        open = false;
    }
}
