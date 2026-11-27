pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.patterns

Page {
    id: root

    title: "Apps"

    property var defaults: ({})
    property var flatpaks: []
    property bool listed: false

    // Reads the list, not byId(), so names appear once the entries have loaded.
    function appName(file) {
        const id = file.replace(/\.desktop$/, "");
        return DesktopEntries.applications.values.find(entry => entry.id === id)?.name ?? id;
    }

    Process {
        running: true
        command: ["sh", "-c", 'echo "browser=$(xdg-settings get default-web-browser)"; echo "files=$(xdg-mime query default inode/directory)"; echo "images=$(xdg-mime query default image/png)"']
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const line of text.trim().split("\n")) {
                    const [kind, id] = line.split("=");
                    found[kind] = id;
                }
                root.defaults = found;
            }
        }
    }
    Process {
        running: true
        command: ["flatpak", "list", "--app", "--columns=name,version"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.flatpaks = text.trim().split("\n").filter(line => line !== "").map(line => line.split("\t"));
                root.listed = true;
            }
        }
    }

    SettingGroup {
        title: "Opens with"

        Repeater {
            model: [
                { key: "browser", title: "Web links", glyph: Icons.publicIcon },
                { key: "files", title: "Folders", glyph: Icons.folder },
                { key: "images", title: "Pictures", glyph: Icons.image },
            ]

            SettingRow {
                required property var modelData
                glyph: modelData.glyph
                title: modelData.title
                subtitle: root.defaults[modelData.key] ? root.appName(root.defaults[modelData.key]) : "Nothing set"
            }
        }
    }

    SettingGroup {
        title: "Installed from Flathub"

        Repeater {
            model: root.flatpaks

            SettingRow {
                required property var modelData
                title: modelData[0]
                subtitle: modelData[1] ?? ""
            }
        }
        SettingRow {
            visible: root.listed && root.flatpaks.length === 0
            title: "None yet"
        }
    }
}
