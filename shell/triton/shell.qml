//@ pragma IconTheme Adwaita
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "services"
import qs.foundations
import qs.surfaces.bar
import qs.surfaces.clipboard
import qs.surfaces.launcher
import qs.surfaces.lock
import qs.surfaces.media
import qs.surfaces.overview
import qs.surfaces.switcher
import qs.surfaces.tray
import qs.surfaces.wallpaper
import qs.surfaces.notifications
import qs.surfaces.osd
import qs.surfaces.power
import qs.surfaces.screenshot
import qs.surfaces.quicksettings

// Triton shell entry point. Thin by design: fonts, then one copy of each
// persistent surface per screen. State lives in singletons and services.

ShellRoot {
    id: shellRoot

    Fonts {}

    DesktopHost {}

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
    LockHost {}

    // Notifications: toasts appear on demand; the center opens from the bell.
    ToastHost {}
    CenterHost {}

    QuickSettingsHost {}

    MediaHost {}
    TrayHost {}

    Variants {
        model: Quickshell.screens

        PowerHost {
            required property var modelData
            screen: modelData
        }
    }

    ClipboardHost {}

    ScreenshotHost {}

    OverviewHost {}

    SwitcherHost {}

    WallpaperHost {}

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
        target: "screenshot"
        function open(): void { ScreenshotState.toggle(); }
        function screen(): void { ScreenshotState.screenNow(); }
        function window(): void { ScreenshotState.windowNow(); }
        function stop(): void { RecordState.stop(); }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { OverviewState.toggle(); }
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
        // To look at the warning on a machine without a battery.
        function battery(percent: int): void { OsdState.warn(percent / 100, "About 40 minutes left", false); }
    }
    IpcHandler {
        target: "media"
        function toggle(): void { MediaService.key("toggle"); }
        function next(): void { MediaService.key("next"); }
        function previous(): void { MediaService.key("previous"); }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { WallpaperState.toggle(); }
    }

    // The same, for the keys: no process is started to deliver them.
    component Shortcut: GlobalShortcut {
        appid: "callisto"
    }
    Shortcut { name: "launcher"; description: "Open the launcher"; onPressed: LauncherState.toggle() }
    Shortcut { name: "quicksettings"; description: "Quick settings"; onPressed: QuickSettingsState.toggle() }
    Shortcut { name: "notifications"; description: "Notifications"; onPressed: NotificationState.toggle() }
    Shortcut { name: "clipboard"; description: "Clipboard history"; onPressed: ClipboardState.toggle() }
    Shortcut { name: "power"; description: "Power menu"; onPressed: PowerState.toggle() }
    Shortcut { name: "screenshot"; description: "Take a screenshot"; onPressed: ScreenshotState.toggle() }
    Shortcut { name: "screenshot-screen"; description: "Capture the whole screen"; onPressed: ScreenshotState.screenNow() }
    Shortcut { name: "screenshot-window"; description: "Capture the focused window"; onPressed: ScreenshotState.windowNow() }
    Shortcut { name: "media"; description: "Media controls"; onPressed: MediaService.togglePopover() }
    Shortcut { name: "nightlight"; description: "Night light on or off"; onPressed: SettingsService.set("display", "nightLight", !SettingsService.nightLight) }
    Shortcut { name: "overview"; description: "Overview of workspaces"; onPressed: OverviewState.toggle() }
    Shortcut { name: "bar"; description: "Show or hide the bar"; onPressed: BarState.toggle() }
    Shortcut { name: "lock"; description: "Lock the screen"; onPressed: LockState.lock() }
    Shortcut { name: "wallpaper"; description: "Choose a wallpaper"; onPressed: WallpaperState.toggle() }

    ThemeSync {}
}
