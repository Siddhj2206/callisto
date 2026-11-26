pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The settings window container (Settings board): 1100x760 r28, sidebar Mica
// w280 + content. Owns which panel shows; panels are leaf components keyed by
// nav index. Board order: Connect/Devices groups are service-backed, Triton
// group is settings-store backed, System is mixed.

Item {
    id: root

    property int panel: 7 // Appearance default; nav indices skip group rows

    width: 1100
    height: 760
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Theme.surface
        border.width: 1
        border.color: "#1FFFFFFF"
    }

    SettingsSidebar {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 280
        selectedIndex: root.panel
        onNavigated: idx => root.panel = idx
    }

    // Content area.
    Item {
        anchors.left: parent.left
        anchors.leftMargin: 280
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        AppearancePanel {
            anchors.fill: parent
            visible: root.panel === 7
            mode: "dark"
            accent: "wallpaper"
            wallpaperPath: Qt.resolvedUrl("../board-wallpaper-1646.jpg").toString().replace("file://", "")
        }

        WindowsPanel {
            anchors.fill: parent
            visible: root.panel === 9
        }
        BarShellPanel {
            anchors.fill: parent
            visible: root.panel === 8
        }
        NotificationsPanel {
            anchors.fill: parent
            visible: root.panel === 10
        }
        NetworkPanel {
            anchors.fill: parent
            visible: root.panel === 0
        }
        BluetoothPanel {
            anchors.fill: parent
            visible: root.panel === 1
        }
        KeyboardPanel {
            anchors.fill: parent
            visible: root.panel === 4
        }
        MousePanel {
            anchors.fill: parent
            visible: root.panel === 5
        }
        PowerPanel {
            anchors.fill: parent
            visible: root.panel === 6
        }
        AppsPanel {
            anchors.fill: parent
            visible: root.panel === 11
        }
        UsersPanel {
            anchors.fill: parent
            visible: root.panel === 12
        }
        SoundPanel {
            anchors.fill: parent
            visible: root.panel === 3
        }
        DisplaysPanel {
            anchors.fill: parent
            visible: root.panel === 2
        }
        AboutPanel {
            anchors.fill: parent
            visible: root.panel === 13
        }

        // Other panels land one at a time with the mock-verify loop; the
        // shell must never show an empty pane.
        TritonText {
            visible: ![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].includes(root.panel)
            anchors.centerIn: parent
            text: "Panel " + root.panel + " — in progress"
            font.pixelSize: 20
            color: Theme.onsurfacevariant
        }
    }
}
