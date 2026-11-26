pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Wallpaper picker visibility + live preview channel. previewPath/previewKind
// override the desktop while picking; closing with revert=true restores the
// store's committed wallpaper, revert=false keeps what was committed.

Singleton {
    property bool open: false
    property string previewPath: ""
    property string previewKind: ""

    function show() {
        open = true;
    }

    function close(revert) {
        open = false;
        if (revert) {
            previewPath = "";
            previewKind = "";
        }
    }
}
