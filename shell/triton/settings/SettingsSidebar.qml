pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The settings sidebar (Settings board): Mica, w280. Search field on top,
// then grouped nav — Connect / Devices / Triton / System. Selected row:
// primary-container pill with 600 weight. Emits navigation; the window owns
// which panel shows.

Rectangle {
    id: root

    property int selectedIndex: 7 // Appearance default
    property string query: ""

    signal navigated(int index)
    signal queryEdited(string text)

    // [label|null for group headers, glyph, title]. Nav indices are baked
    // into the model — computing them per-delegate re-evaluates on every
    // layout pass and polish-loops the Repeater.
    readonly property var entries: [
        { group: "Connect" },
        { glyph: Icons.wifi, title: "Network", nav: 0 },
        { glyph: Icons.bluetooth, title: "Bluetooth", nav: 1 },
        { group: "Devices" },
        { glyph: Icons.monitor, title: "Displays", nav: 2 },
        { glyph: Icons.volumeUp, title: "Sound", nav: 3 },
        { glyph: Icons.keyboard, title: "Keyboard", nav: 4 },
        { glyph: Icons.mouse, title: "Mouse & touchpad", nav: 5 },
        { glyph: Icons.batteryFull, title: "Power", nav: 6 },
        { group: "Triton" },
        { glyph: Icons.palette, title: "Appearance", nav: 7 },
        { glyph: Icons.toolbar, title: "Bar & Shell", nav: 8 },
        { glyph: Icons.webAsset, title: "Windows", nav: 9 },
        { glyph: Icons.notifications, title: "Notifications", nav: 10 },
        { group: "System" },
        { glyph: Icons.apps, title: "Apps", nav: 11 },
        { glyph: Icons.person, title: "Users", nav: 12 },
        { glyph: Icons.info, title: "About", nav: 13 },
    ]

    width: 280
    color: Theme.micaBg
    radius: 0

    Column {
        x: 12
        width: parent.width - 24
        spacing: 2

        Item { width: 1; height: 24 }

        // Search field.
        Rectangle {
            width: parent.width
            height: 52
            radius: 26
            color: "#1AFFFFFF"

            Row {
                x: 18
                width: parent.width - 18
                height: parent.height
                spacing: 12

                TritonIcon {
                    glyph: Icons.search
                    size: 20
                    color: Theme.onsurfacevariant
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextInput {
                    width: parent.width - 70
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "Google Sans Flex"
                    font.pixelSize: 15
                    color: Theme.onsurface
                    clip: true
                    onTextEdited: root.queryEdited(text)

                    TritonText {
                        visible: parent.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search settings"
                        font.pixelSize: 15
                        color: Theme.onsurfacevariant
                    }
                }
            }
        }

        Item { width: 1; height: 4 }

        Repeater {
            model: root.entries

            delegate: Item {
                id: navDelegate
                required property var modelData
                required property int index
                property bool isGroup: modelData.group !== undefined
                property int navIndex: modelData.nav !== undefined ? modelData.nav : -1

                width: parent.width
                height: isGroup ? 40 : 48

                TritonText {
                    visible: navDelegate.isGroup
                    x: 16
                    y: 18
                    text: navDelegate.modelData.group || ""
                    weight: TritonText.Weight.SemiBold
                    font.pixelSize: 12
                    font.letterSpacing: 1.4
                    font.capitalization: Font.AllUppercase
                    color: Theme.onsurfacevariant
                    opacity: 0.8
                }

                Rectangle {
                    visible: !navDelegate.isGroup
                    width: parent.width
                    height: 48
                    radius: 24
                    color: navDelegate.navIndex === root.selectedIndex ? Theme.primaryContainer : "transparent"

                    Row {
                        x: 16
                        width: parent.width - 16
                        height: parent.height
                        spacing: 16

                        TritonIcon {
                            glyph: navDelegate.modelData.glyph || ""
                            size: 22
                            fill: navDelegate.navIndex === root.selectedIndex
                            color: navDelegate.navIndex === root.selectedIndex ? Theme.onprimarycontainer : Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        TritonText {
                            text: navDelegate.modelData.title || ""
                            weight: navDelegate.navIndex === root.selectedIndex ? TritonText.Weight.SemiBold : TritonText.Weight.Medium
                            font.pixelSize: 15
                            color: navDelegate.navIndex === root.selectedIndex ? Theme.onprimarycontainer : Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigated(navDelegate.navIndex)
                    }
                }
            }
        }
    }
}
