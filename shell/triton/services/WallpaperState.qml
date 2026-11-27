pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// The wallpaper: what is set, what the picker is trying out, and what there is
// to choose from.
Singleton {
    id: root

    readonly property string committed: SettingsService.wallpaper
    property string preview: "" // tried on the real desktop while picking
    readonly property string shown: preview || committed

    property bool open: false
    property var items: [] // [{ path, name, source: "system" | "pictures" }]
    property var palette: null // colors the previewed image would give

    function show() {
        preview = "";
        open = true;
        scan.running = true;
        extract();
    }

    // Leaving without choosing puts the old wallpaper back.
    function close() {
        open = false;
        preview = "";
    }

    function toggle() {
        open ? close() : show();
    }

    function tryOn(path) {
        preview = path;
        extract();
    }

    function apply(path) {
        SettingsService.set("appearance", "wallpaper", path);
        close();
    }

    function openFolder() {
        close();
        Quickshell.execDetached(["sh", "-c",
            'd="$(xdg-user-dir PICTURES)"; [ "$d" = "$HOME" ] && d="$HOME/Pictures"; mkdir -p "$d/Wallpapers" && exec uwsm app -- xdg-open "$d/Wallpapers"']);
    }

    // For other programs (Settings): the picker belongs to the shell, because
    // the desktop is its preview.
    function openInShell() {
        Quickshell.execDetached(["qs", "-c", "triton", "ipc", "call", "wallpaper", "toggle"]);
    }

    // ---- what there is --------------------------------------------------------
    Process {
        id: scan
        command: ["sh", "-c", 'list() { find "$2" -maxdepth "$3" -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \\) -printf "$1\\t%p\\n" 2>/dev/null | sort; }\n'
            + 'p="$(xdg-user-dir PICTURES 2>/dev/null)"; [ -z "$p" ] || [ "$p" = "$HOME" ] && p="$HOME/Pictures"\n'
            + 'list system /usr/share/backgrounds/callisto 1; list pictures "$p" 2']
        stdout: StdioCollector {
            onStreamFinished: root.items = text.split("\n").filter(l => l !== "").map(line => {
                const [source, path] = line.split("\t");
                const file = path.slice(path.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
                return { source: source, path: path, name: path === SettingsService.defaultWallpaper ? "Orbit" : file };
            })
        }
    }

    // ---- its colors -----------------------------------------------------------
    // One extraction at a time; browsing on meanwhile asks again afterwards.
    property string extracting: ""

    function extract() {
        if (colors.running)
            return;
        extracting = shown;
        palette = null;
        colors.command = ["callisto-apply", "--scheme", shown];
        colors.running = true;
    }

    Process {
        id: colors
        stdout: StdioCollector {
            id: output
        }
        onExited: code => {
            if (root.extracting !== root.shown) {
                Qt.callLater(root.extract);
                return;
            }
            try {
                root.palette = code === 0 ? JSON.parse(output.text) : null;
            } catch (e) {
                root.palette = null;
            }
        }
    }
}
