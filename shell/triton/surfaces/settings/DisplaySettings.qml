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
        // Widest first, then tallest.
        const parts = size => size.split("x").map(Number);
        return [...found].sort((a, b) => parts(b[0])[0] - parts(a[0])[0] || parts(b[0])[1] - parts(a[0])[1])
            .map(([size, rates]) => ({ size: size, rates: rates.sort((a, b) => b - a) }));
    }

    // Whole hertz, unless two rates would then read the same.
    function hertz(rate, rates) {
        const whole = Math.round(rate);
        return (rates.filter(r => Math.round(r) === whole).length > 1 ? Number(rate).toFixed(2) : whole) + " Hz";
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

                glyph: Icons.monitor
                title: modelData.name
                subtitle: modelData.width + " × " + modelData.height
                    + (info?.refreshRate ? " at " + Math.round(info.refreshRate) + " Hz" : "")
                    + ", scale " + Math.round(modelData.scale * 100) + "%"
                    + (root.trial === null && wanted !== "" && wanted !== size
                        ? ". " + wanted.replace("x", " × ") + " from your next sign-in" : "")

                // A Loader: hidden children would still be given their height.
                below: Loader {
                    width: parent.width
                    active: display.sizes.length > 0
                    visible: active
                    sourceComponent: Flow {
                        spacing: Metrics.panelPad

                        Column {
                            spacing: Metrics.cardActions

                            AppText {
                                role: "labelSmall"
                                tone: "onsurfacevariant"
                                text: "Resolution"
                            }
                            Dropdown {
                                name: "Resolution of " + display.modelData.name
                                options: display.sizes.map(s => ({ value: s.size, label: s.size.replace("x", " × ") }))
                                current: display.size
                                onChosen: value => SettingsService.tryMode(display.modelData.name,
                                    value + "@" + display.sizes.find(s => s.size === value).rates[0])
                            }
                        }
                        Column {
                            visible: display.rates.length > 1
                            spacing: Metrics.cardActions

                            AppText {
                                role: "labelSmall"
                                tone: "onsurfacevariant"
                                text: "Refresh rate"
                            }
                            Dropdown {
                                name: "Refresh rate of " + display.modelData.name
                                options: display.rates.map(r => ({ value: r, label: root.hertz(r, display.rates) }))
                                current: display.rate
                                onChosen: value => SettingsService.tryMode(display.modelData.name,
                                    display.size + "@" + value)
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
            below: SegmentedButton {
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
