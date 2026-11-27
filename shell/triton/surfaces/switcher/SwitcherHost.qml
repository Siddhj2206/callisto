import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.switcher
import qs.tokens

// Alt+Tab on the focused monitor. Nothing is dimmed.
//
// The keys are global shortcuts, not IPC calls: a spawned process could not
// guarantee that "next" arrives before the release of Alt.
Scope {
    GlobalShortcut {
        appid: "callisto"
        name: "switcher-next"
        description: "Next window"
        onPressed: SwitcherState.step(1, false)
    }
    GlobalShortcut {
        appid: "callisto"
        name: "switcher-previous"
        description: "Previous window"
        onPressed: SwitcherState.step(-1, false)
    }
    GlobalShortcut {
        appid: "callisto"
        name: "switcher-same-app"
        description: "Next window of the same app"
        onPressed: SwitcherState.step(1, true)
    }
    GlobalShortcut {
        appid: "callisto"
        name: "switcher-commit"
        description: "Go to the selected window"
        // Bound to the release of Alt, which arrives as a release.
        onReleased: SwitcherState.commit()
    }

    // Focus history has to be running before the first Alt+Tab.
    readonly property var history: WindowService.history

    PanelWindow {
        id: window

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: SwitcherState.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        visible: presence.mapped
        mask: SwitcherState.shown ? null : nothing

        Region { id: nothing }

        readonly property bool open: SwitcherState.shown
        onOpenChanged: {
            if (!open || presence.mapped)
                return;
            const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
            if (focused)
                window.screen = focused;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SwitcherState.cancel()
        }

        Presence {
            id: presence
            show: window.open
            fromScale: Metrics.enterScale
            anchors.centerIn: parent
            width: panel.implicitWidth
            height: panel.implicitHeight

            Material {
                anchors.fill: parent
                kind: "thick"
                radius: Metrics.radiusPanelM
            }
            MouseArea {
                anchors.fill: parent
            }

            SwitcherPanel {
                id: panel
                anchors.fill: parent
                focus: true
                maxWidth: Math.min(Metrics.switcherWidth, window.width - Metrics.barSide * 2)
                windows: SwitcherState.windows
                index: SwitcherState.index
                onActivated: i => {
                    SwitcherState.select(i);
                    SwitcherState.commit();
                }
                onStepped: direction => SwitcherState.step(direction, false)
                onCommitted: SwitcherState.commit()
                onCancelled: SwitcherState.cancel()
                onCloseRequested: SwitcherState.closeCurrent()
                onFloatRequested: SwitcherState.floatCurrent()
            }
        }
    }
}
