pragma Singleton

import Quickshell
import QtQuick
import qs

// The pages of Settings in sidebar order, what can be searched for on them,
// and the accent presets (board seeds; the engine uses the same ones).
Singleton {
    id: root

    readonly property var pages: [
        { name: "network", title: "Network", group: "Connect", glyph: Icons.wifi },
        { name: "bluetooth", title: "Bluetooth", group: "Connect", glyph: Icons.bluetooth },
        { name: "displays", title: "Displays", group: "Devices", glyph: Icons.monitor },
        { name: "sound", title: "Sound", group: "Devices", glyph: Icons.volumeUp },
        { name: "keyboard", title: "Keyboard", group: "Devices", glyph: Icons.keyboard },
        { name: "mouse", title: "Mouse & touchpad", group: "Devices", glyph: Icons.mouse },
        { name: "power", title: "Power", group: "Devices", glyph: Icons.bolt },
        { name: "appearance", title: "Appearance", group: "Triton", glyph: Icons.palette },
        { name: "bar", title: "Bar & Shell", group: "Triton", glyph: Icons.toolbar },
        { name: "windows", title: "Windows", group: "Triton", glyph: Icons.webAsset },
        { name: "notifications", title: "Notifications", group: "Triton", glyph: Icons.notifications },
        { name: "apps", title: "Apps", group: "System", glyph: Icons.apps },
        { name: "users", title: "Users", group: "System", glyph: Icons.person },
        { name: "about", title: "About", group: "System", glyph: Icons.info },
    ]

    readonly property var accents: [
        { value: "planet", label: "Planet", seed: "#2458C8" },
        { value: "hull", label: "Hull", seed: "#D8DEE8" },
        { value: "rock", label: "Rock", seed: "#C0552A" },
        { value: "shadow", label: "Shadow", seed: "#1B2A4A" },
        { value: "haze", label: "Haze", seed: "#4FA3A5" },
    ]

    // [page, what it is called, other words for it]
    readonly property var entries: [
        ["network", "Wi-Fi", "wireless internet ethernet"],
        ["bluetooth", "Bluetooth devices", "pair headphones"],
        ["displays", "Display scale", "resolution zoom text size monitor"],
        ["displays", "Variable refresh rate", "vrr"],
        ["displays", "Night light", "blue light warm colors"],
        ["sound", "Output volume", "speakers headphones"],
        ["sound", "Microphone", "input mic"],
        ["keyboard", "Keyboard layout", "language"],
        ["keyboard", "Key repeat", "rate delay"],
        ["mouse", "Natural scrolling", "touchpad direction"],
        ["mouse", "Tap to click", "touchpad"],
        ["mouse", "Pointer speed", "mouse sensitivity"],
        ["power", "Power mode", "battery performance saver"],
        ["power", "Screen off and suspend", "idle sleep dim"],
        ["appearance", "Dark and light mode", "theme auto"],
        ["appearance", "Accent color", "palette wallpaper"],
        ["appearance", "Match app colors", "gtk flatpak theme apps"],
        ["appearance", "Wallpaper", "background"],
        ["appearance", "Contrast", "accessibility"],
        ["appearance", "Materials", "blur glass mica transparency"],
        ["appearance", "Reduce motion", "animation accessibility"],
        ["bar", "Bar", "pinned autohide hide panel"],
        ["bar", "Reveal delay", "edge"],
        ["bar", "Clock format", "24 hour time"],
        ["windows", "Focus follows mouse", "hover"],
        ["notifications", "Do not disturb", "silence"],
        ["notifications", "Lock screen notifications", "privacy"],
        ["apps", "Default apps and installed apps", "browser flatpak"],
        ["users", "Account", "user name"],
        ["about", "About this computer", "version memory processor kernel"],
    ]

    function page(name) {
        return pages.find(p => p.name === name) ?? null;
    }

    function search(query) {
        const words = query.toLowerCase().split(/\s+/).filter(w => w !== "");
        if (words.length === 0)
            return [];
        return entries.filter(entry => {
            const text = (entry[1] + " " + entry[2] + " " + page(entry[0]).title).toLowerCase();
            return words.every(w => text.includes(w));
        }).map(entry => ({ page: entry[0], title: entry[1] }));
    }
}
