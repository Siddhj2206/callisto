pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
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
import "lock"
import "services"

// Triton shell entry point. Thin by design: fonts, then one copy of each
// persistent surface per screen. State lives in singletons and services.

ShellRoot {
    id: shellRoot

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

    // The session lock exists for the shell's lifetime — it must never be
    // created on demand (window-creation latency at lock time is a security
    // hole) and never destroyed while locked.
    LockWindow {}

    // Edge-reveal sensor: a 2px strip at the top edge of every screen, only
    // in edge/hidden bar modes. Pointer resting here reveals the bar.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 2
            visible: SettingsService.get("shell", "barMode", "pinned") !== "pinned"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: BarState.hovering = true
                onExited: BarState.hovering = false
            }
        }
    }

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

    // OSD producers: the default sink's volume/mute drives the OSD whenever
    // anything (keys, quicksettings slider, another app) changes it. The
    // first observation is skipped so boot doesn't flash the volume OSD.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        property bool primed: false
        property real lastVolume: -1
        property bool lastMuted: false

        function onVolumeChanged() {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
                return;
            const v = Pipewire.defaultAudioSink.audio.volume;
            if (!primed) {
                primed = true;
                lastVolume = v;
                return;
            }
            if (Math.abs(v - lastVolume) > 0.001) {
                lastVolume = v;
                OsdState.show(Osd.Variant.Volume, { value: v, icon: Icons.volumeUp });
            }
        }

        function onMutedChanged() {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
                return;
            const m = Pipewire.defaultAudioSink.audio.muted;
            if (m !== lastMuted) {
                lastMuted = m;
                if (primed) {
                    if (m)
                        OsdState.show(Osd.Variant.Muted, { icon: Icons.volumeOff });
                    else
                        OsdState.show(Osd.Variant.Volume, { value: Pipewire.defaultAudioSink.audio.volume, icon: Icons.volumeUp });
                }
            }
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
    // Brightness OSD producer: /sys/class/backlight is the hardware truth.
    // brightnessctl writes there; the FileView watch fires on change and the
    // OSD reflects actual level regardless of what changed it.
    property int backlightMax: 0
    property real lastBrightnessFrac: -1

    FileView {
        id: backlightMaxFile
        path: "/sys/class/backlight/" + backlightDevice.device + "/max_brightness"
        blockLoading: false
        onLoaded: shellRoot.backlightMax = parseInt(text()) || 0
    }

    FileView {
        id: backlightFile
        path: backlightDevice.device !== ""
            ? "/sys/class/backlight/" + backlightDevice.device + "/brightness"
            : ""
        watchChanges: true
        blockLoading: false
        onLoaded: {
            if (shellRoot.backlightMax <= 0)
                return;
            const frac = (parseInt(text()) || 0) / shellRoot.backlightMax;
            // Skip the boot-time first read — same discipline as volume.
            if (shellRoot.lastBrightnessFrac >= 0 && Math.abs(frac - shellRoot.lastBrightnessFrac) > 0.005)
                OsdState.show(Osd.Variant.Brightness, { value: frac, icon: Icons.brightness7 });
            shellRoot.lastBrightnessFrac = frac;
        }
    }

    // First backlight device — enumerated once at startup.
    Process {
        id: backlightProbe
        command: ["sh", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => backlightDevice.device = data.trim()
        }
    }
    QtObject {
        id: backlightDevice
        property string device: ""
    }

    IpcHandler {
        target: "osd"
        function volume(value: real): void { OsdState.show(Osd.Variant.Volume, { value: value, icon: Icons.volumeUp }); }
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
