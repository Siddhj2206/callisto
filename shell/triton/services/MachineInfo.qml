pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// What this computer is, read once.
Singleton {
    id: root

    property string osName: ""
    property string processor: ""
    property string memory: ""
    property string kernel: ""

    FileView {
        path: "/etc/os-release"
        onLoaded: root.osName = text().match(/^PRETTY_NAME="?([^"\n]*)/m)?.[1] ?? ""
    }
    FileView {
        path: "/proc/cpuinfo"
        onLoaded: root.processor = text().match(/^model name\s*:\s*(.*)$/m)?.[1] ?? ""
    }
    FileView {
        path: "/proc/meminfo"
        onLoaded: {
            const kib = Number(text().match(/^MemTotal:\s*(\d+)/m)?.[1] ?? 0);
            root.memory = (kib / 1048576).toFixed(1) + " GiB";
        }
    }
    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }
}
