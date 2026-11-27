pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQml.Models
import QtQuick
import qs.patterns
import qs.services
import qs.tokens

// The background apps popover under the bar's overflow button.
Popover {
    id: root

    open: TrayState.open
    panelWidth: Metrics.trayWidth
    panelHeight: panel.implicitHeight + Metrics.panelPad * 2
    onDismissed: TrayState.open = false
    onBack: TrayState.back()

    // One opener per level, so a submenu's parents stay loaded.
    Instantiator {
        id: openers
        model: TrayState.path
        delegate: QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }
    readonly property var opener: {
        const depth = TrayState.path.length;
        return depth > 0 && openers.count === depth ? openers.objectAt(depth - 1) : null;
    }

    // Asking for a themed icon the theme lacks draws a checkerboard; an empty
    // source draws the tile's own glyph instead.
    function iconSource(url) {
        const themed = url.startsWith("image://icon/") && !url.includes("?");
        return themed ? Quickshell.iconPath(url.slice("image://icon/".length), true) : url;
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: Metrics.panelPad
        contentHeight: panel.implicitHeight
        interactive: contentHeight > height
        clip: true

        TrayPanel {
            id: panel
            width: parent.width
            apps: TrayState.items.map(i => ({ id: i.id, title: i.title, tooltipTitle: i.tooltipTitle, icon: root.iconSource(i.icon),
                attention: i.status === Status.NeedsAttention, item: i }))
            menuTitle: TrayState.item ? TrayState.item.title || TrayState.item.id : ""
            entries: root.opener ? root.opener.children.values : []
            onActivated: app => TrayState.activate(app.item)
            onMenuRequested: app => TrayState.openMenu(app.item)
            onSecondaryRequested: app => app.item.secondaryActivate()
            onEntryChosen: entry => entry.hasChildren ? TrayState.enter(entry) : TrayState.trigger(entry)
            onBackRequested: TrayState.back()
        }
    }
}
