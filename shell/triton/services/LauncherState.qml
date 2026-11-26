pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Launcher visibility, shared across the bar (which opens it) and the
// launcher window (which closes it). Per-screen bar instances all talk to
// the same launcher — it's a modal singleton by design.

Singleton {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open;
    }

    function dismiss() {
        root.open = false;
    }
}
