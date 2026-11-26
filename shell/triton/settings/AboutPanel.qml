pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// About panel: identity, versions, machine. Read-only in v0.1.

Item {
    id: root

    property string osName: "Callisto OS"
    property string osVersion: "0.1.0 (Phobos)"
    property string shellVersion: "triton 0.1"
    property string deviceName: "neptuno"

    PanelHeader {
        y: 28
        title: "About"
    }

    Column {
        x: 32
        y: 110
        width: root.width - 64
        spacing: 2

        // Identity card: wave + names.
        Rectangle {
            width: parent.width
            height: 120
            radius: 20
            color: Theme.surfaceContainer

            Row {
                x: 24
                height: parent.height
                spacing: 20

                WaveShape {
                    size: 72
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    TritonText {
                        text: root.osName
                        family: TritonText.Family.Display
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 28
                        color: Theme.onsurface
                    }
                    TritonText {
                        text: root.osVersion + " · " + root.shellVersion
                        font.pixelSize: 14
                        color: Theme.onsurfacevariant
                    }
                }
            }
        }

        Item { width: 1; height: 12 }

        SettingRow {
            icon: Icons.monitor
            title: "Device name"
            supporting: root.deviceName
        }
        SettingRow {
            icon: Icons.info
            title: "Desktop"
            supporting: "Hyprland (Wayland)"
        }
    }
}
