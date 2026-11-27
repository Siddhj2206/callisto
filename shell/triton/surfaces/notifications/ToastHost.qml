pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.tokens

// Toasts, top right of the focused screen, under the bar when it is showing.
PanelWindow {
    id: root

    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: Metrics.panelWidth + Metrics.barSide * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Hyprland focuses a new layer that accepts the keyboard, so a toast would
    // steal what is being typed. Ask for it only to let a reply be written.
    WlrLayershell.keyboardFocus: stack.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: NotificationState.toasts.length > 0
    mask: Region { item: stack }

    onVisibleChanged: {
        if (!visible)
            return;
        const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
        if (focused)
            root.screen = focused;
    }

    readonly property bool underBar: BarState.revealed || SettingsService.get("shell", "barMode", "edge") === "pinned"

    Spring {
        id: top
        to: root.underBar ? Metrics.popoverTop : Metrics.barSide
    }

    ToastStack {
        id: stack
        y: top.value
        anchors.right: parent.right
        anchors.rightMargin: Metrics.barSide
        width: Metrics.panelWidth
        items: NotificationState.toasts
        describe: n => NotificationEntry.of(n)
        isSticky: n => NotificationEntry.of(n).critical
        onExpired: n => NotificationState.hideToast(n)
        onClosed: n => NotificationState.dismiss(n)
        onActivated: n => NotificationState.activate(n)
        onActionTriggered: (n, id) => NotificationState.invoke(n, id)
        onReplied: (n, text) => NotificationState.reply(n, text)
    }
}
