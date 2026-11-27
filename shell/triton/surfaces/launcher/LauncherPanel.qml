pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The launcher's contents and keyboard handling. A view of `results`; each is
// { key, section, title, subtitle, icon, glyph, actions: [{ id, label }], quick }.
Item {
    id: root

    property string mode: "apps" // "apps" | "calc" | "commands"
    property string filter: "all"
    property var results: []
    property string expression: ""
    property string calcResult: ""
    property alias query: input.text

    signal queryEdited(string text)
    signal filterPicked(string name)
    signal activated(var row, string actionId)
    signal copyRequested
    signal closed

    readonly property Scheme scheme: Theming.of(root)
    readonly property var filters: [{ id: "all", label: "All" }, { id: "apps", label: "Apps" }, { id: "windows", label: "Windows" }]
    // The best match is shown large only when there is something to match.
    readonly property bool hasTopHit: mode === "apps" && query.trim() !== "" && results.length > 0
    readonly property var listed: hasTopHit ? results.slice(1) : results

    property int selection: 0 // index into results
    property int action: -1 // >= 0 while choosing among the row's actions

    function reset() {
        input.text = "";
        selection = 0;
        action = -1;
        list.contentY = 0;
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    function select(index) {
        if (results.length === 0)
            return;
        selection = (index + results.length) % results.length;
        action = -1;
        reveal();
    }

    function reveal() {
        const item = repeater.itemAt(selection - (hasTopHit ? 1 : 0));
        if (!item)
            list.contentY = 0;
        else if (item.y < list.contentY)
            list.contentY = item.y;
        else if (item.y + item.height > list.contentY + list.height)
            list.contentY = item.y + item.height - list.height;
    }

    function run(index, actionId) {
        if (results[index])
            activated(results[index], actionId);
    }

    function accept() {
        if (mode === "calc") {
            copyRequested();
            return;
        }
        const row = results[selection];
        if (row)
            run(selection, action >= 0 ? row.actions[action].id : "");
    }

    // Returns whether the key was one of ours.
    function handle(key, modifiers) {
        const choices = results[selection]?.actions.length ?? 0;
        if (key === Qt.Key_Down)
            select(selection + 1);
        else if (key === Qt.Key_Up)
            select(selection - 1);
        else if (key === Qt.Key_Tab && choices > 1)
            action = action + 1 >= choices ? -1 : action + 1;
        else if (key === Qt.Key_Right && action >= 0)
            action = (action + 1) % choices;
        else if (key === Qt.Key_Left && action >= 0)
            action = (action + choices - 1) % choices;
        else if (key === Qt.Key_Return || key === Qt.Key_Enter)
            accept();
        else if (key === Qt.Key_Escape)
            action >= 0 ? action = -1 : closed();
        else if (modifiers & Qt.ControlModifier && key >= Qt.Key_1 && key < Qt.Key_1 + filters.length)
            filterPicked(filters[key - Qt.Key_1].id);
        else
            return key === Qt.Key_Tab;
        return true;
    }

    onResultsChanged: {
        if (selection >= results.length)
            selection = 0;
        action = -1;
    }
    onFilterChanged: select(0)

    implicitWidth: mode === "apps" ? Metrics.launcherWidth : Metrics.launcherCompact
    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width

        Item {
            width: parent.width
            height: Metrics.launcherHeader

            WaveShape {
                id: badge
                x: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                width: Metrics.control
                height: width
                color: root.mode === "commands" ? root.scheme.tertiary : root.scheme.primary

                Icon {
                    anchors.centerIn: parent
                    glyph: root.mode === "calc" ? Icons.calculate : root.mode === "commands" ? Icons.chevronRight : Icons.search
                    tone: root.mode === "commands" ? "ontertiary" : "onprimary"
                }
            }

            TextInput {
                id: input
                anchors.left: badge.right
                anchors.leftMargin: Metrics.rowGap
                anchors.right: chips.left
                anchors.rightMargin: Metrics.rowGap
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                focus: true
                font.family: Typography.roles.title.family
                font.pixelSize: Typography.roles.title.size
                color: root.scheme.onsurface
                selectionColor: root.scheme.primary
                selectedTextColor: root.scheme.onprimary
                Accessible.name: "Search"
                onTextEdited: {
                    root.selection = 0;
                    list.contentY = 0;
                    root.queryEdited(text);
                }
                Keys.onPressed: event => event.accepted = root.handle(event.key, event.modifiers)

                AppText {
                    visible: input.text === ""
                    anchors.fill: parent
                    role: "title"
                    tone: "onsurfacevariant"
                    text: "Search apps, > commands, = math"
                }
            }

            Row {
                id: chips
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.cardActions

                Repeater {
                    model: root.mode === "apps" ? root.filters : []

                    Chip {
                        required property var modelData
                        text: modelData.label
                        selected: root.filter === modelData.id
                        activeFocusOnTab: false
                        onClicked: root.filterPicked(modelData.id)
                    }
                }
                Chip {
                    visible: root.mode === "commands"
                    text: "Commands"
                    selected: true
                    activeFocusOnTab: false
                }
            }
        }

        Divider {
            horizontal: true
            width: parent.width
        }

        // Calc
        Item {
            visible: root.mode === "calc"
            width: parent.width
            height: Metrics.topHitDisc + Metrics.panelPad * 2

            Column {
                x: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - copy.width - Metrics.panelPad - Metrics.panelPad - Metrics.panelPad

                AppText {
                    width: parent.width
                    role: "body"
                    tone: "onsurfacevariant"
                    text: root.expression
                }
                AppText {
                    width: parent.width
                    role: "display"
                    tabular: true
                    text: root.calcResult !== "" ? "= " + root.calcResult : "…"
                }
            }
            Button {
                id: copy
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPad
                anchors.verticalCenter: parent.verticalCenter
                glyph: Icons.contentCopy
                text: "Copy"
                interactive: root.calcResult !== ""
                onClicked: root.copyRequested()
            }
        }

        // Results. The height holds still while typing.
        Item {
            visible: root.mode !== "calc"
            width: parent.width
            height: Metrics.launcherBody

            AppText {
                visible: root.results.length === 0
                anchors.centerIn: parent
                role: "body"
                tone: "onsurfacevariant"
                text: "Nothing found"
            }

            Loader {
                id: hit
                active: root.hasTopHit
                x: Metrics.panelPad
                y: Metrics.panelPad
                width: active ? Metrics.topHit : 0
                height: parent.height - Metrics.panelPad * 2
                sourceComponent: TopHit {
                    row: root.results[0]
                    selected: root.selection === 0
                    choosing: selected && root.action >= 0
                    action: root.action
                    onClicked: root.run(0, "")
                    onActionTriggered: id => root.run(0, id)
                }
            }

            Flickable {
                id: list
                anchors.left: hit.right
                anchors.leftMargin: root.hasTopHit ? Metrics.panelPad : 0
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPad
                anchors.top: parent.top
                anchors.topMargin: Metrics.cardActions
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Metrics.cardActions
                contentWidth: width
                contentHeight: rows.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: rows
                    width: parent.width

                    Repeater {
                        id: repeater
                        model: root.listed.length

                        Column {
                            id: slot
                            required property int index
                            readonly property var row: root.listed[index]
                            readonly property int at: index + (root.hasTopHit ? 1 : 0)

                            width: rows.width

                            AppText {
                                visible: slot.index === 0 || root.listed[slot.index - 1]?.section !== slot.row?.section
                                x: Metrics.cardActions
                                height: Metrics.chipHeight
                                role: "labelSmall"
                                tone: "onsurfacevariant"
                                text: slot.row?.section.toUpperCase() ?? ""
                            }
                            ResultRow {
                                width: parent.width
                                row: slot.row
                                selected: root.selection === slot.at
                                choosing: selected && root.action >= 0
                                action: root.action
                                activeFocusOnTab: false
                                onClicked: root.run(slot.at, "")
                                onActionTriggered: id => root.run(slot.at, id)
                            }
                        }
                    }
                }
            }
        }

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

                KeyHint {
                    visible: root.mode !== "calc"
                    keys: ["↑", "↓"]
                    text: "move"
                }
                KeyHint {
                    keys: ["Enter"]
                    text: root.mode === "calc" ? "copy" : "open"
                }
                KeyHint {
                    visible: root.mode !== "calc" && (root.results[root.selection]?.actions.length ?? 0) > 1
                    keys: ["Tab"]
                    text: "actions"
                }
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
