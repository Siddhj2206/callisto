pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// Background apps (StatusNotifier items) and which menu the popover shows.
Singleton {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    property bool open: false
    property var item: null // whose menu is showing, if any
    property var path: [] // that menu and the submenus stepped into

    onOpenChanged: closeMenu()
    onItemsChanged: {
        if (items.length === 0)
            open = false;
        else if (item && !items.includes(item))
            closeMenu();
    }

    function toggle() {
        open = !open;
    }

    function openMenu(of) {
        if (!of.hasMenu)
            return;
        item = of;
        path = [of.menu];
    }

    function enter(entry) {
        path = path.concat([entry]);
    }

    function back() {
        if (path.length > 1)
            path = path.slice(0, -1);
        else if (item)
            closeMenu();
        else
            open = false;
    }

    function closeMenu() {
        item = null;
        path = [];
    }

    function activate(of) {
        if (of.onlyMenu) {
            openMenu(of);
            return;
        }
        of.activate();
        open = false;
    }

    function trigger(entry) {
        entry.triggered();
        open = false;
    }
}
