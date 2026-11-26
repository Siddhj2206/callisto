pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Overview visibility — opened by keybind or gesture; closes on jump or Esc.

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }

    function dismiss() {
        open = false;
    }
}
