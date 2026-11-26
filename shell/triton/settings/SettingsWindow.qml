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

        // Other panels land one at a time with the mock-verify loop; the
        // shell must never show an empty pane.
        TritonText {
            visible: root.panel !== 7
            anchors.centerIn: parent
            text: "Panel " + root.panel + " — in progress"
            font.pixelSize: 20
            color: Theme.onsurfacevariant
        }
    }
}
