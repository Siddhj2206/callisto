pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services
import qs.tokens

// The window switcher while Alt is held. The panel waits a moment before it
// shows, so a quick Alt+Tab swaps windows without drawing anything.
Singleton {
    id: root

    property bool active: false
    property bool shown: false
    property var windows: [] // taken when it opens; focus changes do not reorder it
    property int index: 0
    readonly property var current: windows[index] ?? null

    function step(direction, sameApp) {
        if (active) {
            if (windows.length > 0)
                index = (index + direction + windows.length) % windows.length;
            return;
        }
        let list = WindowService.windows;
        if (sameApp && list.length > 0)
            list = list.filter(w => w.appId === list[0].appId);
        if (list.length === 0)
            return;
        windows = list;
        index = direction > 0 ? Math.min(1, list.length - 1) : list.length - 1;
        active = true;
        delay.restart();
        WindowService.refresh();
    }

    function select(i) {
        index = i;
    }

    function commit() {
        if (!active)
            return;
        const chosen = current;
        cancel();
        if (chosen)
            WindowService.focus(chosen.address);
    }

    function cancel() {
        delay.stop();
        active = false;
        shown = false;
    }

    function closeCurrent() {
        if (!current)
            return;
        WindowService.close(current.address);
        const gone = current.address;
        windows = windows.filter(w => w.address !== gone);
        if (windows.length === 0)
            cancel();
        else
            index = Math.min(index, windows.length - 1);
    }

    function floatCurrent() {
        if (!current)
            return;
        const address = current.address;
        WindowService.toggleFloating(address);
        windows = windows.map(w => w.address === address ? Object.assign({}, w, { floating: !w.floating }) : w);
    }

    Timer {
        id: delay
        interval: Motion.switcherOpenDelay
        onTriggered: root.shown = root.active
    }
}
