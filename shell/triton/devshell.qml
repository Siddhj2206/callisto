import Quickshell
import QtQuick
import "launcher"
import "osd"
import "components"

// Dev harness: renders the launcher in its board states with mock data, so
// geometry and type can be verified pixel-exactly in the headless harness.
// Bar verification lives in git history; current focus is the launcher.

ShellRoot {
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

    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"

        // The board's own wallpaper, cropped exactly like the reference:
        // object-fit cover at 1646x1029 from a larger image. We mimic with a
        // scaled fill and the 30% black scrim the board draws over it.
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
            fillMode: Image.Pad
        }
        Rectangle {
            anchors.fill: parent
            color: "#4D000000" // rgb(0 0 0 / .3)
        }

        // OSD variants, positioned bottom-center as they appear in use.
        Osd {
            variant: Osd.Variant.Volume
            value: 0.62
            x: 84
            y: 1004
        }

        Osd {
            variant: Osd.Variant.Muted
            icon: Icons.volumeOff
            x: 84
            y: 886
        }

        Osd {
            variant: Osd.Variant.Brightness
            icon: Icons.brightness6
            value: 0.7
            x: 474
            y: 886
        }

        Osd {
            variant: Osd.Variant.MicOff
            icon: Icons.micOff
            x: 1254
            y: 886
        }

        Osd {
            variant: Osd.Variant.Keyboard
            icon: Icons.keyboard
            fillIcon: false
            text: "DE"
            subtext: "Deutsch"
            x: 134
            y: 960
        }

        Osd {
            variant: Osd.Variant.Track
            trackTitle: "Lofi Windows"
            trackArtist: "Tomppabeats"
            x: 856
            y: 960
        }

        Osd {
            variant: Osd.Variant.BatteryLow
            icon: Icons.batteryAlert
            batteryPercentText: "Battery 15%"
            batteryTimeText: "About 40 minutes left"
            x: 1246
            y: 960
        }

        // Main state: typing "con" — matches the board exactly.
        LauncherPanel {
            x: 64; y: 84
            query: "con"
            topHitGlyph: Icons.terminal
            topHitName: "Console"
            topHitSubtitle: "Terminal emulator · GNOME"
            topHitActions: [
                { text: "Open" },
                { text: "New window", veil: true },
            ]
            results: [
                { kind: "label", text: "Apps" },
                { kind: "row", glyph: Icons.contacts, fillGlyph: true, title: "Contacts", subtitle: "Address book",
                  discColor: Theme.tertiaryContainer, discContentColor: Theme.ontertiarycontainer },
                { kind: "row", glyph: Icons.settingsRemote, fillGlyph: true, title: "Connections", subtitle: "Remote desktops" },
                { kind: "label", text: "Windows" },
                { kind: "row", glyph: Icons.terminal, title: "Console", subtitle: "~/niri-shell", tag: "Work",
                  discColor: Theme.primaryContainer, discContentColor: Theme.onprimarycontainer },
                { kind: "label", text: "Files" },
                { kind: "row", glyph: Icons.description, title: "config.kdl", subtitle: "~/.config/niri",
                  discColor: Theme.surfaceContainerHighest, discContentColor: Theme.onsurfacevariant },
            ]
        }

        // Command state: typing "> dark" — tertiary badge, tinted chip.
        LauncherPanel {
            x: 1010; y: 370
            mode: LauncherPanel.Mode.Commands
            query: "dark"
            results: [
                { kind: "row", glyph: Icons.darkMode, fillGlyph: true, title: "Toggle dark style",
                  subtitle: "Currently on · follows schedule", selected: true, keyHint: "Enter", keyHint: "Enter" },
                { kind: "row", glyph: Icons.palette, title: "Regenerate colors from wallpaper",
                  subtitle: "matugen · tonal-spot" },
                { kind: "row", glyph: Icons.wallpaper, title: "Change wallpaper…",
                  subtitle: "Pictures/Wallpapers" },
            ]
        }

        // Calc state: typing "1248 / 4".
        LauncherPanel {
            x: 1010; y: 84
            mode: LauncherPanel.Mode.Calc
            query: "1248 / 4"
            calcExpression: "1,248 ÷ 4"
            calcResult: "= 312"
        }
    }
}
