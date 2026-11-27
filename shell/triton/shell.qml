pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "overview"
import "wallpaper"
import "settings"
import "lock"
import "services"
import qs.foundations
import qs.surfaces.bar
import qs.surfaces.clipboard
import qs.surfaces.launcher
import qs.surfaces.notifications
import qs.surfaces.osd
import qs.surfaces.power
import qs.surfaces.quicksettings

// Triton shell entry point. Thin by design: fonts, then one copy of each
// persistent surface per screen. State lives in singletons and services.

ShellRoot {
    id: shellRoot

    Fonts {}

    Variants {
        model: Quickshell.screens

        Desktop {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        BarHost {
            required property var modelData
            screen: modelData
        }
    }

    // The launcher is a modal singleton — one instance regardless of screen
    // count. It positions itself on the focused output at runtime.
    LauncherHost {}

    // OSD: state-driven, invisible until a producer shows something.
    OsdHost {}
    OsdProducers {}

    // The session lock exists for the shell's lifetime — it must never be
    // created on demand (window-creation latency at lock time is a security
    // hole) and never destroyed while locked.
    LockWindow {}

    // Notifications: toasts appear on demand; the center opens from the bell.
    ToastHost {}
    CenterHost {}

    QuickSettingsHost {}

    Variants {
        model: Quickshell.screens

        PowerHost {
            required property var modelData
            screen: modelData
        }
    }

    ClipboardHost {}

    OverviewWindow {}

    WallpaperWindow {}

    // The settings app: a normal floating window inside the same shell
    // process. It shares SettingsService and Theme singletons with the
    // shell — editing a setting repaints the shell in the same frame the
    // engine writes, no IPC needed. Toggled by the launcher/QS buttons via
    // the state below.
    FloatingWindow {
        id: settingsWindow
        visible: SettingsAppState.open
        title: "Callisto Settings" // hyprland.lua floats it by this title
        color: "transparent"
        implicitWidth: 1100
        implicitHeight: 700 // fits an 800px screen under the pinned bar
        minimumSize: Qt.size(900, 620)
        onVisibleChanged: {
            if (!visible)
                SettingsAppState.open = false;
        }

        SettingsWindow {
            anchors.fill: parent
        }
    }

    // IPC: Hyprland keybinds and user scripts drive shell surfaces through
    // `qs ipc call <target> <function>` — no socket hacks, no dotfile
    // editing. The settings app uses the same channel for live preview.
    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle(); }
    }
    IpcHandler {
        target: "quicksettings"
        function toggle(): void { QuickSettingsState.toggle(); }
        function page(name: string): void { QuickSettingsState.show(name); }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationState.toggle(); }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void { ClipboardState.toggle(); }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { PowerState.toggle(); }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { OverviewState.toggle(); }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { SettingsAppState.toggle(); }
    }
    IpcHandler {
        target: "bar"
        function toggle(): void { BarState.toggle(); }
    }
    IpcHandler {
        target: "lock"
        function lock(): void { LockState.lock(); }
    }
    IpcHandler {
        target: "osd"
        function volume(value: real): void { OsdState.show("volume", value); }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { WallpaperState.open ? WallpaperState.close(true) : WallpaperState.show(); }
    }

    // Live theme application: the theme engine writes user-resolved tokens
    // here when the settings app changes accent/contrast/mode. watchChanges
    // re-fires onLoaded on every write, so accent changes repaint the whole
    // shell in the same frame the engine writes — no restart, no re-login.
    FileView {
        id: userTokens
        path: Quickshell.env("HOME") + "/.config/callisto/tokens.json"
        watchChanges: true
        atomicWrites: true
        blockLoading: false
        onFileChanged: reload()
        onLoaded: {
            try {
                Theme.reduceMotion = SettingsService.get("shell", "reduceMotion", false);
                Theme.applyUserTokens(JSON.parse(text()));
            } catch (e) {
                console.warn("triton: user tokens unparseable, keeping compiled defaults:", e);
            }
        }
        onLoadFailed: {
            // No user tokens yet — compiled defaults apply. Normal before
            // the first settings change.
        }
    }

    // Auto light/dark: re-resolve the scheme on the minute boundary. Cheap —
    // applyUserTokens only repaints when active_mode flips the palette.
    Timer {
        interval: 60000
        running: Theme.userTokens !== null
        repeat: true
        property string lastMode: ""
        onTriggered: {
            const before = Theme.activeMode;
            Theme.applyUserTokens(Theme.userTokens);
            // Crossing the day/night boundary re-runs the engine so external
            // apps (gtk, foot, flatpaks via the portal) follow the flip.
            if (Theme.activeMode !== before)
                autoFlipProc.running = true;
        }
    }

    Process {
        id: autoFlipProc
        command: ["callisto-apply"]
    }

    // reduceMotion follows the store reactively — it lives outside the
    // tokens file since it's an accessibility preference, not a color role.
    Connections {
        target: SettingsService
        function onStoreChanged() {
            Theme.reduceMotion = SettingsService.get("shell", "reduceMotion", false);
        }
    }
}
