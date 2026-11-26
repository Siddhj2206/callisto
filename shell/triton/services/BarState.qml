pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Bar reveal state for hidden/edge autohide modes. In pinned mode the bar
// ignores this entirely. Revealing also happens automatically while the
// launcher is open — the bar is the launcher's visual context.

Singleton {
    property bool revealed: false

    function toggle() {
        revealed = !revealed;
    }
}
