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

    // [label|null for group headers, glyph, title]
    readonly property var entries: [
        { group: "Connect" },
        { glyph: Icons.wifi, title: "Network" },
        { glyph: Icons.bluetooth, title: "Bluetooth" },
        { group: "Devices" },
        { glyph: Icons.monitor, title: "Displays" },
        { glyph: Icons.volumeUp, title: "Sound" },
        { glyph: Icons.keyboard, title: "Keyboard" },
        { glyph: Icons.mouse, title: "Mouse & touchpad" },
        { glyph: Icons.batteryFull, title: "Power" },
        { group: "Triton" },
        { glyph: Icons.palette, title: "Appearance" },
        { glyph: Icons.toolbar, title: "Bar & Shell" },
        { glyph: Icons.webAsset, title: "Windows" },
        { glyph: Icons.notifications, title: "Notifications" },
        { group: "System" },
        { glyph: Icons.apps, title: "Apps" },
        { glyph: Icons.person, title: "Users" },
        { glyph: Icons.info, title: "About" },
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
                // nav indices count only non-group entries
                property int navIndex: {
                    let n = -1;
                    for (let i = 0; i <= index; i++)
                        if (root.entries[i].group === undefined)
                            n++;
                    return n;
                }

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
