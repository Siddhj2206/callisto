pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight level. sysfs is read (and watched, so changes from anywhere show
// up); brightnessctl writes. Unavailable on desktops and most VMs.
Singleton {
    id: root

    property string device: ""
    property int maximum: 0
    property real level: -1 // 0..1, -1 until read
    readonly property bool available: level >= 0

    property real pending: -1

    function set(value) {
        pending = Math.max(0.01, Math.min(1, value));
        if (!writer.running)
            write();
    }

    function write() {
        writer.command = ["brightnessctl", "set", Math.round(pending * 100) + "%"];
        pending = -1;
        writer.running = true;
    }

    // Drags arrive faster than brightnessctl exits; the latest value wins.
    Process {
        id: writer
        onExited: {
            if (root.pending >= 0)
                root.write();
        }
    }

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => root.device = data.trim()
        }
    }

    FileView {
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
        onLoaded: {
            root.maximum = parseInt(text()) || 0;
            reading.reload();
        }
    }

    FileView {
        id: reading
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.maximum > 0)
                root.level = (parseInt(text()) || 0) / root.maximum;
        }
    }
}
