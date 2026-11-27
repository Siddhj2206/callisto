pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "About"

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

    Row {
        spacing: Metrics.panelPad

        OsLogo {
            width: Metrics.avatarLarge
            height: width
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter

            AppText {
                role: "title"
                text: "Callisto"
            }
            AppText {
                tone: "onsurfacevariant"
                text: root.osName
            }
        }
    }

    SettingGroup {
        title: "This computer"

        Repeater {
            model: [
                ["Name", PowerService.hostName],
                ["Processor", root.processor],
                ["Memory", root.memory],
                ["Kernel", root.kernel],
            ]

            SettingRow {
                required property var modelData
                title: modelData[0]
                subtitle: modelData[1]
            }
        }
    }
}
