pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../services"

// Clipboard surface: fullscreen overlay with the 35% scrim and the centered
// panel. Closes on paste or click-off — the board's behavior rules.

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: ClipboardState.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
        anchors.fill: parent
        color: "#59000000" // 35% scrim

        MouseArea {
            anchors.fill: parent
            onClicked: ClipboardState.dismiss()
        }
    }

    ClipboardPanel {
        anchors.centerIn: parent
        visible: root.visible

        // Real history from the clipwatch daemon. Pinned entries first,
        // then everything else, sectioned like the board.
        items: {
            const rows = [];
            const pinned = ClipboardState.entries.filter(e => e.pinned);
            const rest = ClipboardState.entries.filter(e => !e.pinned);
            if (pinned.length > 0) {
                rows.push({ kind: "section", text: "Pinned" });
                for (const e of pinned)
                    rows.push({ kind: "row", glyph: Icons.notes, title: e.preview, meta: "Pinned", pinned: true, entry: e });
            }
            if (rest.length > 0) {
                rows.push({ kind: "section", text: "History" });
                for (const e of rest)
                    rows.push({ kind: "row", glyph: Icons.notes, title: e.preview, meta: "Text", entry: e });
            }
            if (rows.length === 0)
                rows.push({ kind: "section", text: "Clipboard is empty — copy something first" });
            return rows;
        }

        onPasted: idx => {
            // Rows carry their entry object — the index is into the items
            // array the panel itself renders, headers included.
            const target = items[idx];
            if (target && target.entry)
                ClipboardState.paste(target.entry);
            ClipboardState.dismiss();
        }
    }
}
