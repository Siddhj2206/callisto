pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "osd"
import "notifications"
import "quicksettings"
import "power"
import "clipboard"
import "overview"
import "wallpaper"
import "settings"
import "services"

// Triton shell entry point. Thin by design: fonts, then one copy of each
// persistent surface per screen. State lives in singletons and services.

ShellRoot {
    // The bundled Triton fonts. Static instances per family/weight — Qt
    // resolves "Jost SemiBold" as a distinct family, which is more reliable
    // than weight matching against a variable font. Paths are relative to
    // shell.qml so this works in the repo and installed layouts.
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols-Filled.ttf") }

    Variants {
        model: Quickshell.screens

        Desktop {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // The launcher is a modal singleton — one instance regardless of screen
    // count. It positions itself on the focused output at runtime.
    Launcher {}

    // OSD: state-driven, invisible until a producer shows something.
    OsdWindow {}

    // Notifications: toasts appear on demand; the center opens from the bell.
    ToastWindow {}
    CenterWindow {}

    QsWindow {}

    PowerWindow {}

    ClipboardWindow {}

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
        title: "Settings"
        color: "transparent"
        implicitWidth: 1100
        implicitHeight: 760
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
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationState.centerOpen = !NotificationState.centerOpen; }
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
}
