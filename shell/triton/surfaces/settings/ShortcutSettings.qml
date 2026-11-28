pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Shortcuts"
    subtitle: "Click a shortcut, then press the keys you want for it."

    // The id or index being listened for.
    property var listening: null
    // The custom shortcut in the form: -1 a new one, null none.
    property var editing: null

    // Without this the compositor would act on the keys instead of passing them.
    ShortcutInhibitor {
        window: root.QsWindow.window
        enabled: root.listening !== null
    }

    // Only for its names of keys.
    KeyCombo {
        id: labels
        visible: false
    }

    function listen(ident, on) {
        if (on)
            listening = ident;
        else if (listening === ident)
            listening = null;
    }

    SettingGroup {
        title: "Yours"

        Repeater {
            model: ShortcutsService.custom

            ShortcutRow {
                required property var modelData
                required property int index

                ident: index
                title: modelData.title
                about: modelData.command
                keys: modelData.keys
                listening: root.listening === index
                onListen: on => root.listen(index, on)

                below: Row {
                    spacing: Metrics.buttonGap
                    Button {
                        text: "Edit"
                        variant: "text"
                        onClicked: root.editing = index
                    }
                    Button {
                        text: "Delete"
                        variant: "text"
                        onClicked: {
                            root.listening = null;
                            root.editing = null;
                            ShortcutsService.remove(index);
                        }
                    }
                }
            }
        }
        SettingRow {
            glyph: Icons.add
            title: "Add a shortcut"
            subtitle: "Run a command with keys of your choice"
            clickable: true
            visible: root.editing === null
            onClicked: root.editing = -1
        }
        Loader {
            width: parent.width
            active: root.editing !== null
            visible: active
            sourceComponent: SettingRow {
                id: form

                readonly property var current: ShortcutsService.custom[root.editing] ?? null
                readonly property bool complete: name.text.trim() !== "" && command.text.trim() !== ""

                function save() {
                    if (!complete)
                        return;
                    const added = root.editing < 0;
                    const index = added ? ShortcutsService.custom.length : root.editing;
                    ShortcutsService.save(root.editing, name.text.trim(), command.text.trim());
                    root.editing = null;
                    // A new one is no use without its keys.
                    if (added)
                        root.listening = index;
                }

                title: root.editing < 0 ? "New shortcut" : "Edit shortcut"
                Component.onCompleted: {
                    name.text = current?.title ?? "";
                    command.text = current?.command ?? "";
                    name.focusInput();
                }

                below: Column {
                    width: parent.width
                    spacing: Metrics.cardActions

                    TextField {
                        id: name
                        width: parent.width
                        placeholder: "Name"
                        onAccepted: command.focusInput()
                    }
                    TextField {
                        id: command
                        width: parent.width
                        placeholder: "Command, for example: flatpak run org.mozilla.firefox"
                        onAccepted: form.save()
                    }
                    Row {
                        spacing: Metrics.cardActions
                        Button {
                            text: "Save"
                            opacity: form.complete ? 1 : 0.5
                            onClicked: form.save()
                        }
                        Button {
                            text: "Cancel"
                            variant: "text"
                            onClicked: root.editing = null
                        }
                    }
                }
            }
        }
    }

    Repeater {
        model: ShortcutsService.groups

        SettingGroup {
            id: group

            required property string modelData

            title: modelData === "Fixed" ? "Cannot be changed" : modelData

            Repeater {
                model: ShortcutsService.shipped.filter(b => b.group === group.modelData)

                ShortcutRow {
                    required property var modelData

                    ident: modelData.id
                    title: modelData.title
                    readonly property var also: ShortcutsService.alsoOf(modelData.id)
                    about: also.length ? "Also " + also.map(keys => labels.label(keys)).join(", ") : ""
                    keys: ShortcutsService.keysOf(modelData.id)
                    fixed: modelData.fixed === true
                    listening: root.listening === modelData.id
                    onListen: on => root.listen(modelData.id, on)

                    IconButton {
                        visible: modelData.id in ShortcutsService.changes
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Icons.undo
                        label: "Reset " + modelData.title
                        onClicked: ShortcutsService.reset(modelData.id)
                    }
                }
            }
        }
    }

    Button {
        visible: ShortcutsService.changed
        text: "Reset all shortcuts"
        variant: "veil"
        onClicked: {
            root.listening = null;
            ShortcutsService.resetAll();
        }
    }
}
