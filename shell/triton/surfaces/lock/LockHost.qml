pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import qs
import qs.foundations
import qs.services
import qs.surfaces.lock
import qs.tokens

// The session lock, one surface per screen. This object lives as long as the
// shell: destroying a live lock would leave the screen blank. Always dark.
WlSessionLock {
    id: root

    locked: LockState.locked

    WlSessionLockSurface {
        id: surface
        color: "black"

        ThemeScope {
            mode: "dark"
            anchors.fill: parent

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            LockScreen {
                id: screen
                anchors.fill: parent
                focus: true

                readonly property var battery: UPower.displayDevice
                readonly property bool hasBattery: battery?.ready && battery.isLaptopBattery
                readonly property int minutes: Math.max(0, Math.floor((clock.date.getTime() - LockState.lockedAt) / 60000))

                wallpaper: {
                    if (!SettingsService.get("appearance", "wallpaperOnLock", true))
                        return "";
                    const path = SettingsService.get("appearance", "wallpaper", "/usr/share/backgrounds/callisto/wallpaper.jpg");
                    return path !== "" ? "file://" + path : "";
                }
                date: Qt.formatDate(clock.date, "dddd, d MMMM")
                time: Qt.formatTime(clock.date, SettingsService.get("shell", "clockFormat", "24h") === "24h" ? "HH:mm" : "h:mm")
                name: PowerService.userName || Quickshell.env("USER") || ""
                caption: minutes === 0 ? "Locked" : "Locked " + minutes + (minutes === 1 ? " minute ago" : " minutes ago")
                error: LockState.error
                busy: LockState.busy
                waiting: SettingsService.get("notifications", "lockscreenNotifications", true)
                    ? NotificationState.groups.map(g => ({ app: g.app, count: g.items.length })) : []
                networkGlyph: NetworkService.wired ? Icons.lan : NetworkService.online ? Icons.wifi : ""
                batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : -1
                batteryGlyph: !hasBattery ? ""
                    : battery.state === UPowerDeviceState.Charging ? Icons.batteryChargingFull : Icons.battery5Bar

                onSubmitted: password => LockState.submit(password)

                Component.onCompleted: reset()

                Connections {
                    target: LockState
                    function onFailed() { screen.reject(); }
                    function onLockedChanged() {
                        if (LockState.locked)
                            screen.reset();
                    }
                }
            }
        }
    }
}
