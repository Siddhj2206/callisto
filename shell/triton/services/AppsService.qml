pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// What opens what, and the installed Flatpaks.
Singleton {
    id: root

    property var defaults: ({}) // "browser" | "files" | "images" -> desktop file
    property var flatpaks: [] // [[name, version]]
    property bool listed: false

    function refresh() {
        openers.running = true;
        installed.running = true;
    }

    // Reads the list, not byId(), so names appear once the entries have loaded.
    function appName(file) {
        const id = file.replace(/\.desktop$/, "");
        return DesktopEntries.applications.values.find(entry => entry.id === id)?.name ?? id;
    }

    Process {
        id: openers
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
        id: installed
        command: ["flatpak", "list", "--app", "--columns=name,version"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.flatpaks = text.trim().split("\n").filter(line => line !== "").map(line => line.split("\t"));
                root.listed = true;
            }
        }
    }
}
