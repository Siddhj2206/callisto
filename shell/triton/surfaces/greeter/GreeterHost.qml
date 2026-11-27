pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.foundations
import qs.services
import qs.surfaces.greeter

// One login window per screen; the first takes the keyboard.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window
        required property var modelData
        readonly property bool primary: modelData === Quickshell.screens[0]

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            GreeterScreen {
                id: screen
                anchors.fill: parent
                focus: true
                wallpaper: "file:///usr/share/backgrounds/callisto/wallpaper.jpg"
                date: Qt.formatDate(clock.date, "dddd, d MMMM")
                time: Qt.formatTime(clock.date, "HH:mm")
                users: GreeterState.users
                selected: GreeterState.selected
                busy: GreeterState.busy
                error: GreeterState.error
                hint: GreeterState.live && GreeterState.user?.login === "user" ? "Live session password: live" : ""
                networkGlyph: SessionStatus.networkGlyph
                batteryGlyph: SessionStatus.batteryGlyph
                batteryPercent: SessionStatus.batteryPercent

                onPicked: index => GreeterState.select(index)
                onSubmitted: password => GreeterState.submit(password)
                onRestartRequested: GreeterState.power("reboot")
                onShutDownRequested: GreeterState.power("poweroff")

                Component.onCompleted: reset()

                Connections {
                    target: GreeterState
                    function onFailed() { screen.reject(); }
                }
            }
        }
    }
}
