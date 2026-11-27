pragma ComponentBehavior: Bound

import QtQuick
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.tokens

Page {
    id: root

    title: "About"

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
                text: MachineInfo.osName
            }
        }
    }

    SettingGroup {
        title: "This computer"

        Repeater {
            model: [
                ["Name", PowerService.hostName],
                ["Processor", MachineInfo.processor],
                ["Memory", MachineInfo.memory],
                ["Kernel", MachineInfo.kernel],
            ]

            SettingRow {
                required property var modelData
                title: modelData[0]
                subtitle: modelData[1]
            }
        }
    }
}
