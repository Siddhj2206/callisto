pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// The session lock: ext-session-lock via WlSessionLock, the Triton lockscreen
// as the surface content, PAM authentication through LockState. The object
// lives outside any visibility flip — destroying a live lock paints the
// screen solid and strands the session, so the lock object exists for the
// shell's entire lifetime and only its `locked` flag moves.

WlSessionLock {
    id: lock

    locked: LockState.locked

    WlSessionLockSurface {
        color: "#000000"

        // Wallpaper backdrop, heavily dimmed — stands in for the board's
        // blur (real blur needs compositor cooperation; dim reads the same).
        Image {
            anchors.fill: parent
            visible: SettingsService.get("appearance", "wallpaperOnLock", true)
            source: {
                const wp = SettingsService.get("appearance", "wallpaper", "/usr/share/backgrounds/callisto/wallpaper.jpg");
                return wp !== "" ? "file://" + wp : "";
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
        Rectangle {
            anchors.fill: parent
            color: "#99000000"
        }

        LockScreen {
            anchors.fill: parent
            // Lockscreen notification rows honor the settings toggle.
            notifications: SettingsService.get("notifications", "lockscreenNotifications", true)
                ? NotificationState.groups.map(g => ({
                    app: g.app,
                    glyph: g.items && g.items[0] ? g.items[0].appIcon || "" : "",
                }))
                : []
            userName: Quickshell.env("USER") || "user"
            userInitials: (Quickshell.env("USER") || "u").charAt(0).toUpperCase()
            fieldState: LockState.fieldState

            dateText: Qt.formatDate(new Date(), "dddd, MMMM d")
            timeText: Qt.formatTime(new Date(), SettingsService.get("shell", "clockFormat", "24h") === "24h" ? "hh:mm" : "h:mm AP")
            lockedText: "Locked"

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    parent.timeText = Qt.formatTime(new Date(), SettingsService.get("shell", "clockFormat", "24h") === "24h" ? "hh:mm" : "h:mm AP");
                    parent.dateText = Qt.formatDate(new Date(), "dddd, MMMM d");
                }
            }

            onPasswordSubmitted: pw => LockState.submit(pw)
        }
    }
}
