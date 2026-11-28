pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "Displays"

    readonly property var monitors: Hyprland.monitors.values
    readonly property real scale: SettingsService.get("display", "scale", monitors[0]?.scale ?? 1)

    readonly property var trial: SettingsService.trial
    // The display whose resolutions are listed.
    property string opened: ""
    // The compositor was asked for the tried size and did not take it: some
    // graphics (virtual machines above all) only do so at the next sign-in.
    property bool refused: false

    function sizeOf(monitor) {
        return monitor.width + "x" + monitor.height;
    }

    // "1920x1080@59.94Hz" from Hyprland, as sizes with their refresh rates.
    function sizes(available) {
        const found = new Map();
        for (const entry of available ?? []) {
            const [size, rate] = entry.replace(/Hz$/, "").split("@");
            if (!found.has(size))
                found.set(size, []);
            if (!found.get(size).includes(rate))
                found.get(size).push(rate);
        }
        // Too small for Settings itself, and for undoing the choice.
        for (const size of [...found.keys()]) {
            const [w, h] = size.split("x").map(Number);
            if (w < 1024 || h < 720)
                found.delete(size);
        }
        const area = size => size.split("x").reduce((a, b) => a * b, 1);
        return [...found].sort((a, b) => area(b[0]) - area(a[0]))
            .map(([size, rates]) => ({ size: size, rates: rates.sort((a, b) => b - a) }));
    }

    // Hyprland announces neither a scale nor a mode change, so ask again.
    onScaleChanged: refresh.restart()
    onTrialChanged: {
        if (trial === null)
            refused = false;
        refresh.restart();
    }
    Component.onCompleted: Hyprland.refreshMonitors()
    Timer {
        id: refresh
        interval: Motion.monitorRefresh
        onTriggered: {
            Hyprland.refreshMonitors();
            verdict.restart();
        }
    }
    // The answer to the refresh takes a moment.
    Timer {
        id: verdict
        interval: Motion.monitorSettle
        onTriggered: {
            const monitor = root.monitors.find(m => m.name === root.trial?.output);
            root.refused = monitor !== undefined && !root.trial.mode.startsWith(root.sizeOf(monitor) + "@");
        }
    }

    SettingGroup {
        title: "Connected"

        SettingRow {
            visible: root.trial !== null
            title: root.refused ? "Not possible while you are signed in" : "Keep this resolution?"
            subtitle: (root.refused ? "It can be used from your next sign-in. Asking for " : "Going back in ")
                + (root.trial?.left ?? 0) + (root.refused ? " more seconds" : " seconds")
            tone: "primary"
            below: Row {
                spacing: Metrics.cardActions
                Button {
                    text: root.refused ? "Use at next sign-in" : "Keep"
                    onClicked: SettingsService.keepMode()
                }
                Button {
                    text: root.refused ? "Cancel" : "Revert"
                    variant: "text"
                    onClicked: SettingsService.revertMode()
                }
            }
        }

        Repeater {
            model: root.monitors

            SettingRow {
                id: display

                required property var modelData
                readonly property var info: modelData.lastIpcObject
                readonly property var sizes: root.sizes(info?.availableModes)
                readonly property string size: root.sizeOf(modelData)
                // What the next session will use; "preferred" is listed first.
                readonly property string stored: SettingsService.get("display", "modes", {})[modelData.name] ?? "preferred"
                readonly property string wanted: stored === "preferred"
                    ? (info?.availableModes?.[0] ?? "").split("@")[0] : stored.split("@")[0]
                readonly property var rates: sizes.find(s => s.size === size)?.rates ?? []
                // The listed rate nearest to the one in use.
                readonly property string rate: rates.reduce((best, r) =>
                    Math.abs(r - info.refreshRate) < Math.abs(best - info.refreshRate) ? r : best, rates[0] ?? "")
                readonly property bool open: root.opened === modelData.name

                glyph: Icons.monitor
                title: modelData.name
                subtitle: modelData.width + " × " + modelData.height
                    + (info?.refreshRate ? " at " + Math.round(info.refreshRate) + " Hz" : "")
                    + ", scale " + Math.round(modelData.scale * 100) + "%"
                    + (root.trial === null && wanted !== "" && wanted !== size
                        ? ". " + wanted.replace("x", " × ") + " from your next sign-in" : "")
                clickable: sizes.length > 0
                onClicked: root.opened = open ? "" : modelData.name

                Icon {
                    visible: display.sizes.length > 0
                    glyph: display.open ? Icons.keyboardArrowUp : Icons.keyboardArrowDown
                }

                // A Loader: hidden children would still be given their height.
                below: Loader {
                    width: parent.width
                    active: display.open
                    visible: active
                    sourceComponent: Column {
                        spacing: Metrics.cardActions

                        AppText {
                            role: "labelSmall"
                            tone: "onsurfacevariant"
                            text: "Resolution"
                        }
                        ChoiceChips {
                            width: parent.width
                            options: display.sizes.map(s => ({ value: s.size, label: s.size.replace("x", " × ") }))
                            current: display.size
                            onChosen: value => {
                                if (value !== display.size)
                                    SettingsService.tryMode(display.modelData.name,
                                        value + "@" + display.sizes.find(s => s.size === value).rates[0]);
                            }
                        }
                        AppText {
                            visible: display.rates.length > 1
                            role: "labelSmall"
                            tone: "onsurfacevariant"
                            text: "Refresh rate"
                        }
                        ChoiceChips {
                            visible: display.rates.length > 1
                            width: parent.width
                            options: display.rates.map(r => ({ value: r, label: Math.round(r) + " Hz" }))
                            current: display.rate
                            onChosen: value => {
                                if (value !== display.rate)
                                    SettingsService.tryMode(display.modelData.name, display.size + "@" + value);
                            }
                        }
                    }
                }
            }
        }
    }

    SettingGroup {
        title: "Picture"

        SettingRow {
            title: "Scale"
            subtitle: "How large everything is drawn, on every display"
            below: ChoiceChips {
                width: parent.width
                options: [1, 1.25, 1.5, 1.75, 2].map(v => ({ value: v, label: v * 100 + "%" }))
                current: root.scale
                onChosen: value => SettingsService.set("display", "scale", value)
            }
        }
        SettingRow {
            title: "Variable refresh rate"
            subtitle: "On displays that support it"
            Switch {
                label: "Variable refresh rate"
                checked: SettingsService.get("display", "vrr", true)
                onToggled: on => SettingsService.set("display", "vrr", on)
            }
        }
        SettingRow {
            glyph: Icons.nightlight
            title: "Night light"
            subtitle: "Warmer colors, easier on the eyes at night"
            Switch {
                label: "Night light"
                checked: SettingsService.nightLight
                onToggled: on => SettingsService.set("display", "nightLight", on)
            }
        }
    }
}
