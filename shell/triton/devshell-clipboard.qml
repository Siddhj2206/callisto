import Quickshell
import QtQuick
import "clipboard"
import "components"

// Clipboard verification: board state — pinned ssh entry, screenshot
// selected, sensitive item with countdown.

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/Jost-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/GoogleSansFlex-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/TritonSymbols-Filled.ttf") }

    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"

        Rectangle { anchors.fill: parent; color: "#111318" }
        Rectangle { anchors.fill: parent; color: "#59000000" }

        ClipboardPanel {
            x: 323
            y: 120
            previewTitle: "Screenshot 2026-11-21 20.14.02.png"
            previewMeta: "PNG · 1646 × 1029 · 412 KB · from Screenshot, 2 min ago"
            previewIsImage: true
            items: [
                { kind: "section", text: "Pinned" },
                { kind: "row", glyph: Icons.terminal, mono: true, title: "ssh sid@neptuno.local -p 2222", meta: "Terminal · pinned", pinned: true },
                { kind: "section", text: "Today" },
                { kind: "row", glyph: Icons.image, fillGlyph: true, title: "Screenshot 2026-11-21 20.14.02.png", meta: "1646 × 1029 · 412 KB · 2 min ago", selected: true },
                { kind: "row", glyph: Icons.palette, mono: true, title: "#2458C8", meta: "Color · from Appearance" },
                { kind: "row", glyph: Icons.notes, title: "Meeting notes: the bar reveals in 150 ms and never…", meta: "Text · Notes · 14 min ago" },
                { kind: "row", glyph: Icons.link, title: "Material 3 Expressive", meta: "design.google · 22 min ago" },
                { kind: "row", glyph: Icons.folder, title: "3 files", meta: "Documents · 1 h ago" },
                { kind: "row", glyph: Icons.key, title: "••••••••••••", meta: "Hidden · from Passwords · clears in 24 s", sensitive: true, countdown: 24 },
            ]
        }
    }
}
