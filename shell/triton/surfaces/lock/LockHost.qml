pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
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

                readonly property int minutes: Math.max(0, Math.floor((clock.date.getTime() - LockState.lockedAt) / 60000))

                wallpaper: {
                    if (!SettingsService.wallpaperOnLock)
                        return "";
                    const path = SettingsService.wallpaper;
                    return path !== "" ? "file://" + path : "";
                }
                date: Qt.formatDate(clock.date, "dddd, d MMMM")
                time: Qt.formatTime(clock.date, SettingsService.clock24h ? "HH:mm" : "h:mm")
                name: PowerService.displayName
                caption: minutes === 0 ? "Locked" : "Locked " + minutes + (minutes === 1 ? " minute ago" : " minutes ago")
                error: LockState.error
                busy: LockState.busy
                waiting: SettingsService.lockscreenNotifications
                    ? NotificationState.groups.map(g => ({ app: g.app, count: g.items.length })) : []
                networkGlyph: SessionStatus.networkGlyph
                batteryGlyph: SessionStatus.batteryGlyph
                batteryPercent: SessionStatus.batteryPercent

                media: MediaService.present ? MediaService.current : null
                onMediaToggled: MediaService.togglePlaying()
                onMediaNextRequested: MediaService.next()
                onMediaPreviousRequested: MediaService.previous()

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
