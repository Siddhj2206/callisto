pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "bar"
import "launcher"
import "osd"
import "notifications"
import "quicksettings"
import "power"
import "clipboard"
import "overview"

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
}
