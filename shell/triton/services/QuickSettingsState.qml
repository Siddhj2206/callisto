pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Quick settings visibility, opened from the bar's stat pill (volume icon)
// or a keybind. Modal singleton like the launcher.

Singleton {
    property bool open: false
    property string page: "" // "" is the main page; "wifi", "bluetooth", "sound"

    function toggle() {
        if (open)
            dismiss();
        else
            show("");
    }

    function show(name) {
        page = name;
        open = true;
    }

    function dismiss() {
        open = false;
    }
}
