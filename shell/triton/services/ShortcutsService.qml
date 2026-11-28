pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// The keyboard shortcuts: the shipped ones (keybindings.json, which Hyprland
// binds from too), what the user changed, and the user's own.

Singleton {
    id: root

    property var shipped: []
    readonly property var changes: SettingsService.get("keyboard", "shortcuts", {})
    readonly property var custom: SettingsService.get("keyboard", "custom", [])
    readonly property var bindings: shipped.map(b => Object.assign({}, b, {
        keys: b.id in changes ? changes[b.id] : b.keys,
        changed: b.id in changes,
    }))
    readonly property var groups: [...new Set(shipped.map(b => b.group))]
    readonly property bool changed: Object.keys(changes).length > 0

    FileView {
        path: "/usr/share/callisto/keybindings.json"
        onLoaded: root.shipped = JSON.parse(text())
    }

    function keysOf(id) {
        return bindings.find(b => b.id === id)?.keys ?? "";
    }

    // The other keys that do the same, as hyprland.lua binds them: none once the
    // shortcut is changed, and never keys the user has put to another use.
    function alsoOf(id) {
        if (id in changes)
            return [];
        const chosen = Object.values(changes).concat(custom.map(c => c.keys));
        return (shipped.find(b => b.id === id)?.also ?? []).filter(keys => !chosen.includes(keys) && !keys.includes("mouse_"));
    }

    // What already answers to these keys, other than `except` (a shipped id or
    // the index of a custom one).
    function owner(keys, except) {
        const shippedOwner = bindings.find(b => b.keys === keys && b.id !== except);
        if (shippedOwner)
            return { id: shippedOwner.id, title: shippedOwner.title, fixed: shippedOwner.fixed === true };
        const index = custom.findIndex((c, i) => c.keys === keys && i !== except);
        return index < 0 ? null : { id: index, title: custom[index].title, fixed: false };
    }

    // "" takes the shortcut away.
    function assign(id, keys) {
        if (typeof id === "number") {
            SettingsService.set("keyboard", "custom", custom.map((c, i) => i === id ? Object.assign({}, c, { keys: keys }) : c));
            return;
        }
        const next = Object.assign({}, changes);
        if (keys === shipped.find(b => b.id === id)?.keys)
            delete next[id];
        else
            next[id] = keys;
        SettingsService.set("keyboard", "shortcuts", next);
    }

    // Back to the shipped keys, taking them from whatever has them now.
    function reset(id) {
        const keys = shipped.find(b => b.id === id).keys;
        const other = owner(keys, id);
        if (other)
            assign(other.id, "");
        assign(id, keys);
    }

    function resetAll() {
        SettingsService.set("keyboard", "shortcuts", {});
        // The user's own give way where they sit on a shipped shortcut.
        const taken = shipped.map(b => b.keys);
        if (custom.some(c => taken.includes(c.keys)))
            SettingsService.set("keyboard", "custom", custom.map(c => taken.includes(c.keys) ? Object.assign({}, c, { keys: "" }) : c));
    }

    // index -1 adds one.
    function save(index, title, command) {
        const next = custom.slice();
        if (index < 0)
            next.push({ title: title, keys: "", command: command });
        else
            next[index] = { title: title, keys: next[index].keys, command: command };
        SettingsService.set("keyboard", "custom", next);
    }

    function remove(index) {
        SettingsService.set("keyboard", "custom", custom.filter((c, i) => i !== index));
    }

    // A key press as Hyprland would write it, or "" while it is not yet a
    // usable shortcut (a modifier on its own, a bare letter).
    function combo(event) {
        let name = "";
        const key = event.key;
        // By position, since Shift turns the number row into symbols.
        const row = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
        const named = new Map([
            [Qt.Key_Space, "Space"], [Qt.Key_Return, "Return"], [Qt.Key_Enter, "Return"],
            [Qt.Key_Tab, "Tab"], [Qt.Key_Backtab, "Tab"], [Qt.Key_Escape, "Escape"],
            [Qt.Key_Backspace, "BackSpace"], [Qt.Key_Delete, "Delete"], [Qt.Key_Insert, "Insert"],
            [Qt.Key_Home, "Home"], [Qt.Key_End, "End"], [Qt.Key_PageUp, "Prior"], [Qt.Key_PageDown, "Next"],
            [Qt.Key_Left, "Left"], [Qt.Key_Right, "Right"], [Qt.Key_Up, "Up"], [Qt.Key_Down, "Down"],
            [Qt.Key_Print, "Print"], [Qt.Key_SysReq, "Print"], [Qt.Key_Pause, "Pause"],
            [Qt.Key_Comma, "comma"], [Qt.Key_Less, "comma"], [Qt.Key_Period, "period"], [Qt.Key_Greater, "period"],
            [Qt.Key_Slash, "slash"], [Qt.Key_Question, "slash"], [Qt.Key_Backslash, "backslash"], [Qt.Key_Bar, "backslash"],
            [Qt.Key_Semicolon, "semicolon"], [Qt.Key_Colon, "semicolon"], [Qt.Key_Apostrophe, "apostrophe"],
            [Qt.Key_QuoteDbl, "apostrophe"], [Qt.Key_BracketLeft, "bracketleft"], [Qt.Key_BraceLeft, "bracketleft"],
            [Qt.Key_BracketRight, "bracketright"], [Qt.Key_BraceRight, "bracketright"], [Qt.Key_Minus, "minus"],
            [Qt.Key_Underscore, "minus"], [Qt.Key_Equal, "equal"], [Qt.Key_Plus, "equal"],
            [Qt.Key_QuoteLeft, "grave"], [Qt.Key_AsciiTilde, "grave"],
        ]);
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            name = String.fromCharCode(key);
        else if (key >= Qt.Key_F1 && key <= Qt.Key_F24)
            name = "F" + (key - Qt.Key_F1 + 1);
        else if (event.nativeScanCode >= 10 && event.nativeScanCode <= 19)
            name = row[event.nativeScanCode - 10];
        else if (key >= Qt.Key_0 && key <= Qt.Key_9)
            name = String.fromCharCode(key);
        else
            name = named.get(key) ?? "";
        if (name === "")
            return "";
        const held = [[Qt.MetaModifier, "SUPER"], [Qt.ControlModifier, "CTRL"], [Qt.AltModifier, "ALT"], [Qt.ShiftModifier, "SHIFT"]]
            .filter(m => event.modifiers & m[0]).map(m => m[1]);
        const alone = /^(F\d+|Print|Pause)$/.test(name);
        if (!alone && !held.some(m => m !== "SHIFT"))
            return "";
        return [...held, name].join(" + ");
    }
}
