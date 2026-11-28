import QtQuick
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

// One shortcut. Click it and press the new keys.
SettingRow {
    id: row

    // A shipped shortcut's id, or the index of one of the user's own.
    property var ident
    property string keys: ""
    property string about: "" // subtitle when nothing is going on
    property bool fixed: false
    property bool listening: false
    // Keys pressed that something else has, and what that is.
    property string wanted: ""
    property var taken: null

    // Asks the page to listen on this row, or on none.
    signal listen(bool on)

    function press(combo) {
        const other = ShortcutsService.owner(combo, ident);
        if (!other) {
            ShortcutsService.assign(ident, combo);
            listen(false);
        } else {
            wanted = combo;
            taken = other;
        }
    }

    subtitle: taken ? caps.label(wanted) + (taken.fixed ? " cannot be changed: " : " is used by: ") + taken.title
        : listening ? "Press the new keys. Escape cancels." : about
    tone: taken ? "error" : listening ? "primary" : "onsurfacevariant"
    clickable: !fixed
    onClicked: listen(true)
    onListeningChanged: {
        taken = null;
        if (listening)
            catcher.forceActiveFocus();
    }

    KeyCombo {
        id: caps
        anchors.verticalCenter: parent.verticalCenter
        keys: row.taken ? row.wanted : row.keys
    }
    Button {
        visible: row.taken !== null && !row.taken.fixed
        anchors.verticalCenter: parent.verticalCenter
        text: "Replace"
        variant: "container"
        onClicked: {
            ShortcutsService.assign(row.taken.id, "");
            ShortcutsService.assign(row.ident, row.wanted);
            row.listen(false);
        }
    }
    Button {
        visible: row.listening && row.keys !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: "Remove"
        variant: "text"
        onClicked: {
            ShortcutsService.assign(row.ident, "");
            row.listen(false);
        }
    }
    Button {
        visible: row.listening
        anchors.verticalCenter: parent.verticalCenter
        text: "Cancel"
        variant: "text"
        onClicked: row.listen(false)
    }
    Item {
        id: catcher
        height: parent.height
        Keys.onPressed: event => {
            event.accepted = true;
            if (!row.listening)
                return;
            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                row.listen(false);
                return;
            }
            const combo = ShortcutsService.combo(event);
            if (combo !== "")
                row.press(combo);
        }
    }
}
