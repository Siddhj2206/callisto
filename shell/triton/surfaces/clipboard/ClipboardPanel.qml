pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// Clipboard history: a searchable list with a preview of the selection. A pure
// view of `entries` ({ key, kind, title, detail, path, pinned }).
Item {
    id: root

    property var entries: []
    property bool available: true
    property string previewText: ""
    property string filter: "all"
    property alias query: header.query
    property int selection: 0
    property bool confirming: false // asking before the history is wiped

    signal selected(string key)
    signal used(string key, bool paste)
    signal pinRequested(string key, bool pinned)
    signal deleteRequested(string key)
    signal wipeRequested
    signal closed

    readonly property var filters: [
        { id: "all", label: "All" }, { id: "text", label: "Text" }, { id: "image", label: "Images" },
        { id: "link", label: "Links" }, { id: "pinned", label: "Pinned" }
    ]
    readonly property var matching: {
        const needle = query.trim().toLowerCase();
        return entries.filter(e => (filter === "all" || (filter === "pinned" ? e.pinned : filter === "text"
                    ? e.kind === "text" || e.kind === "color" : e.kind === filter))
            && (needle === "" || (e.title + " " + e.detail).toLowerCase().includes(needle)));
    }
    readonly property var current: matching[selection] ?? null
    readonly property string currentKey: current?.key ?? ""
    onCurrentKeyChanged: selected(currentKey)

    function reset() {
        header.query = "";
        filter = "all";
        selection = 0;
        confirming = false;
        list.positionViewAtBeginning();
    }

    function focusInput() {
        header.focusInput();
    }

    function select(index) {
        if (matching.length === 0)
            return;
        selection = (index + matching.length) % matching.length;
        list.positionViewAtIndex(selection, ListView.Contain);
    }

    function pickFilter(id) {
        filter = id;
        selection = 0;
        list.positionViewAtBeginning();
    }

    function togglePin() {
        if (current)
            pinRequested(current.key, !current.pinned);
    }

    function remove() {
        if (current)
            deleteRequested(current.key);
    }

    function wipe() {
        confirming = false;
        wipeRequested();
    }

    // Returns whether the key was one of ours.
    function handle(key, modifiers) {
        const control = modifiers & Qt.ControlModifier;
        if (confirming) {
            if (key === Qt.Key_Return || key === Qt.Key_Enter)
                wipe();
            else if (key === Qt.Key_Escape)
                confirming = false;
            return true;
        }
        if (key === Qt.Key_Down)
            select(selection + 1);
        else if (key === Qt.Key_Up)
            select(selection - 1);
        else if ((key === Qt.Key_Return || key === Qt.Key_Enter) && current)
            used(current.key, !(modifiers & Qt.ShiftModifier));
        else if (control && key === Qt.Key_P)
            togglePin();
        else if (control && (modifiers & Qt.ShiftModifier) && key === Qt.Key_Delete)
            confirming = true;
        // Delete edits the query unless there is nothing ahead of the cursor.
        else if (key === Qt.Key_Delete && header.atEnd)
            remove();
        else if (key === Qt.Key_Escape)
            query !== "" ? (query = "", selection = 0) : closed();
        else if (control && key >= Qt.Key_1 && key < Qt.Key_1 + filters.length)
            pickFilter(filters[key - Qt.Key_1].id);
        else
            return key === Qt.Key_Tab;
        return true;
    }

    onMatchingChanged: {
        if (selection >= matching.length)
            selection = Math.max(0, matching.length - 1);
    }

    implicitWidth: Metrics.clipWidth
    implicitHeight: Metrics.clipHeight

    SearchHeader {
        id: header
        width: parent.width
        glyph: Icons.contentPaste
        placeholder: "Search clipboard"
        onEdited: root.selection = 0
        onKeyPressed: event => event.accepted = root.handle(event.key, event.modifiers)

        Repeater {
            model: root.filters

            Chip {
                required property var modelData
                text: modelData.label
                selected: root.filter === modelData.id
                activeFocusOnTab: false
                onClicked: root.pickFilter(modelData.id)
            }
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: Metrics.chipHeight
            glyph: Icons.deleteSweep
            label: "Clear history"
            activeFocusOnTab: false
            onClicked: root.confirming = true
        }
    }

    Item {
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right

        ListView {
            id: list
            visible: !root.confirming && root.matching.length > 0
            x: Metrics.cardActions
            y: Metrics.cardActions
            width: Metrics.clipList
            height: parent.height - Metrics.cardActions * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: Metrics.listGap
            model: root.matching

            delegate: ResultRow {
                required property var modelData
                required property int index
                width: ListView.view.width
                activeFocusOnTab: false
                selected: index === root.selection
                row: ({
                    title: modelData.title,
                    subtitle: modelData.detail,
                    icon: modelData.kind === "image" ? "file://" + modelData.path : "",
                    picture: true,
                    glyph: modelData.kind === "link" ? Icons.link : modelData.kind === "color" ? Icons.palette
                        : modelData.kind === "image" ? Icons.image : Icons.notes,
                    mark: modelData.pinned ? Icons.pushPin : "",
                    actions: []
                })
                // A click selects; a click on the selection pastes.
                onClicked: index === root.selection ? root.used(modelData.key, true) : root.select(index)
            }
        }

        ClipboardPreview {
            visible: !root.confirming && root.current !== null
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: list.right
            anchors.right: parent.right
            anchors.margins: Metrics.cardPad
            entry: root.current
            text: root.previewText
            onPasteRequested: root.used(root.currentKey, true)
            onPinRequested: root.togglePin()
            onDeleteRequested: root.remove()
        }

        Column {
            visible: !root.confirming && root.matching.length === 0
            anchors.centerIn: parent
            spacing: Metrics.cardActions

            WaveShape {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Metrics.swatch
                height: width
                color: Theming.of(root).veil
            }
            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "headline"
                text: !root.available ? "Clipboard history is unavailable"
                    : root.entries.length === 0 ? "Nothing copied yet" : "No matches"
            }
            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.available && root.entries.length === 0
                role: "body"
                tone: "onsurfacevariant"
                text: "Text and images you copy show up here."
            }
        }

        Column {
            visible: root.confirming
            anchors.centerIn: parent
            spacing: Metrics.panelGap

            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "headline"
                text: "Clear clipboard history?"
            }
            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "body"
                tone: "onsurfacevariant"
                text: "Pinned items stay."
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Metrics.cardActions

                Button {
                    variant: "veil"
                    text: "Cancel"
                    activeFocusOnTab: false
                    onClicked: {
                        root.confirming = false;
                        root.focusInput();
                    }
                }
                Button {
                    text: "Clear history"
                    activeFocusOnTab: false
                    onClicked: root.wipe()
                }
            }
        }
    }

    Column {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width

        Divider {
            horizontal: true
            width: parent.width
        }
        Item {
            width: parent.width
            height: Metrics.hintHeight

            Row {
                x: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.panelPad

                KeyHint { keys: ["Enter"]; text: "paste" }
                KeyHint { keys: ["Shift+Enter"]; text: "copy" }
                KeyHint { keys: ["Ctrl+P"]; text: "pin" }
                KeyHint { keys: ["Del"]; text: "delete" }
            }
            KeyHint {
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                keys: ["Esc"]
                text: "close"
            }
        }
    }
}
