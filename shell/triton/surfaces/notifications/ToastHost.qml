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
    WlrLayershell.namespace: "triton-glass"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Hyprland focuses a new layer that accepts the keyboard, so a toast would
    // steal what is being typed. Ask for it only to let a reply be written.
    WlrLayershell.keyboardFocus: stack.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // Each toast comes and goes through its own Presence (Toast.qml), so this
    // only maps the surface. Never in a screenshot, so that cuts at once.
    visible: NotificationState.toasts.length > 0 && !ScreenshotState.open
    mask: Region { item: stack }

    onVisibleChanged: {
        if (!visible)
            return;
        const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
        if (focused)
            root.screen = focused;
    }

    readonly property bool underBar: BarState.revealed || SettingsService.barMode === "pinned"

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
        // A zero timeout is the sender asking to stay until answered.
        isSticky: n => NotificationEntry.of(n).critical || n.expireTimeout === 0
        onExpired: n => NotificationState.hideToast(n)
        onClosed: n => NotificationState.dismiss(n)
        onActivated: n => NotificationState.activate(n)
        onActionTriggered: (n, id) => NotificationState.invoke(n, id)
        onReplied: (n, text) => NotificationState.reply(n, text)
    }
}
