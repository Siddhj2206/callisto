pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"
import "../services"

// The settings window container (Settings board): 1100x760 r28, sidebar Mica
// w280 + content. Owns which panel shows; panels are leaf components keyed by
// nav index. Board order: Connect/Devices groups are service-backed, Triton
// group is settings-store backed, System is mixed.

Item {
    id: root

    property int panel: SettingsAppState.panel // nav indices skip group rows

    width: 1100
    height: 760
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Theme.surface
        border.width: 1
        border.color: Theme.veilMid
    }

    SettingsSidebar {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 280
        selectedIndex: root.panel
        onNavigated: idx => SettingsAppState.panel = idx
    }

    // Content area.
    Item {
        anchors.left: parent.left
        anchors.leftMargin: 280
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        // M8 fix: one panel alive at a time. All fourteen used to be
        // instantiated eagerly — every store binding live, the wallpaper
        // preview decoded before the window ever opened.
        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (root.panel) {
                case 0: return networkPanel;
                case 1: return bluetoothPanel;
                case 2: return displaysPanel;
                case 3: return soundPanel;
                case 4: return keyboardPanel;
                case 5: return mousePanel;
                case 6: return powerPanel;
                case 7: return appearancePanel;
                case 8: return barShellPanel;
                case 9: return windowsPanel;
                case 10: return notificationsPanel;
                case 11: return appsPanel;
                case 12: return usersPanel;
                case 13: return aboutPanel;
                default: return appearancePanel;
                }
            }
        }
    }

    Component { id: networkPanel; NetworkPanel {} }
    Component { id: bluetoothPanel; BluetoothPanel {} }
    Component { id: displaysPanel; DisplaysPanel {} }
    Component { id: soundPanel; SoundPanel {} }
    Component { id: keyboardPanel; KeyboardPanel {} }
    Component { id: mousePanel; MousePanel {} }
    Component { id: powerPanel; PowerPanel {} }
    Component {
        id: appearancePanel
        AppearancePanel {
            onWallpaperBrowse: {
                SettingsAppState.open = false;
                WallpaperState.show();
            }
        }
    }
    Component { id: barShellPanel; BarShellPanel {} }
    Component { id: windowsPanel; WindowsPanel {} }
    Component { id: notificationsPanel; NotificationsPanel {} }
    Component { id: appsPanel; AppsPanel {} }
    Component { id: usersPanel; UsersPanel {} }
    Component { id: aboutPanel; AboutPanel {} }
}
