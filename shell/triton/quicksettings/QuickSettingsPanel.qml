pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// Quick settings panel (QuickSettings board): Glass w400 r32 padding 20.
// Two pages share the panel — the tile grid and drill-ins (Wi-Fi). Nothing
// leaves the panel; deep settings open the floating app, that's its signal.
//
// Main page: header (title + settings gear), 2-col tile grid h72 r36 —
// ON tiles are primary/on-primary, OFF tiles white/.12 — sliders with
// leading icons, then the bottom row (All settings + power).
//
// Drill-in: back button + page title + master switch, connected network
// list (22/6 radii progression, first/last), footer action.

Rectangle {
    id: root

    enum Page { Main, Wifi }

    property int page: QuickSettingsPanel.Page.Main

    // Tile model: [{glyph, fillGlyph?, label, sublabel, on, drillable}]
    property var tiles: []
    // Wi-Fi page model: [{glyph, fillGlyph?, name, status, trailing, connected}]
    property var wifiNetworks: []
    property bool wifiEnabled: true
    property real brightness: 0.7
    property real volume: 0.42

    signal tileClicked(int idx)
    signal drillIn(int idx)
    signal back()
    signal wifiToggled(bool v)
    signal networkClicked(int idx)
    signal brightnessMoved(real v)
    signal volumeMoved(real v)
    signal allSettings()
    signal powerClicked()
    signal gearClicked()

    width: 400
    radius: 32
    color: Theme.glassBg
    implicitHeight: bodyCol.implicitHeight + 40
    clip: true

    Column {
        id: bodyCol
        x: 20
        y: 20
        width: parent.width - 40
        spacing: 0

        // ---- Header ----
        Item {
            width: parent.width
            height: 44

            Row {
                height: parent.height
                spacing: 10

                // Back button, drill-in only.
                Rectangle {
                    visible: root.page !== QuickSettingsPanel.Page.Main
                    width: 44
                    height: 44
                    radius: 22
                    color: Theme.veil

                    TritonIcon {
                        anchors.centerIn: parent
                        glyph: Icons.arrowBack
                        size: 24
                        color: Theme.onsurface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.back()
                    }
                }

                TritonText {
                    text: root.page === QuickSettingsPanel.Page.Main ? "Quick settings" : "Wi-Fi"
                    family: TritonText.Family.Display
                    weight: TritonText.Weight.Medium
                    font.pixelSize: 22
                    color: Theme.onsurface
                    boxHeight: 44
                }
            }

            // Trailing: gear (main) or master switch (drill-in).
            Rectangle {
                visible: root.page === QuickSettingsPanel.Page.Main
                anchors.right: parent.right
                width: 44
                height: 44
                radius: 22
                color: Theme.veil

                TritonIcon {
                    anchors.centerIn: parent
                    glyph: Icons.settings
                    size: 24
                    color: Theme.onsurface
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.gearClicked()
                }
            }

            TritonSwitch {
                visible: root.page !== QuickSettingsPanel.Page.Main
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                on: root.wifiEnabled
                onToggled: v => root.wifiToggled(v)
            }
        }

        Item { width: 1; height: 16 }

        // ---- Main page ----
        Column {
            visible: root.page === QuickSettingsPanel.Page.Main
            width: parent.width
            spacing: 8

            // Tile grid: 2 columns, h72 r36.
            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.tiles

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: (parent.width - 8) / 2
                        height: 72
                        radius: 36
                        color: modelData.on ? Theme.primary : Theme.veilMid
                        property bool tileOn: modelData.on === true
                        readonly property color ink: tileOn ? Theme.onprimary : Theme.onsurface

                        Row {
                            x: 12
                            height: parent.height
                            spacing: 12

                            TritonIcon {
                                glyph: modelData.glyph || ""
                                fill: modelData.fillGlyph || false
                                size: 24
                                color: ink
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                TritonText {
                                    text: modelData.label || ""
                                    weight: TritonText.Weight.SemiBold
                                    font.pixelSize: 14
                                    color: ink
                                }
                                TritonText {
                                    text: modelData.sublabel || ""
                                    font.pixelSize: 12
                                    color: ink
                                    opacity: 0.8
                                }
                            }
                        }

                        TritonIcon {
                            visible: modelData.drillable === true
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: Icons.chevronRight
                            size: 22
                            color: ink
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                // Chevron zone drills; body toggles.
                                if (modelData.drillable && mouse.x > width - 44)
                                    root.drillIn(index);
                                else
                                    root.tileClicked(index);
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 10 }

            // Sliders.
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 12

                    TritonIcon {
                        glyph: Icons.lightMode
                        size: 24
                        color: Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonSlider {
                        width: parent.width - 36
                        value: root.brightness
                        onMoved: v => root.brightnessMoved(v)
                    }
                }
                Row {
                    width: parent.width
                    spacing: 12

                    TritonIcon {
                        glyph: Icons.volumeUp
                        size: 24
                        color: Theme.onsurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonSlider {
                        width: parent.width - 36
                        value: root.volume
                        onMoved: v => root.volumeMoved(v)
                    }
                }
            }

            Item { width: 1; height: 10 }

            // Bottom row.
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width - 56
                    height: 48
                    radius: 24
                    color: Theme.primaryContainer

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        TritonIcon {
                            glyph: Icons.tune
                            size: 20
                            color: Theme.onprimarycontainer
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        TritonText {
                            text: "All settings"
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 14
                            color: Theme.onprimarycontainer
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.allSettings()
                    }
                }

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Theme.veilMid

                    TritonIcon {
                        anchors.centerIn: parent
                        glyph: Icons.powerSettingsNew
                        size: 24
                        color: Theme.onsurface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.powerClicked()
                    }
                }
            }
        }

        // ---- Wi-Fi drill-in ----
        Column {
            visible: root.page === QuickSettingsPanel.Page.Wifi
            width: parent.width
            spacing: 2

            Repeater {
                model: root.wifiNetworks

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 60
                    color: "transparent"

                    // Connected-list radius progression: first 22/22/6/6,
                    // middle 6, last 6/6/22/22.
                    RoundedRect {
                        anchors.fill: parent
                        radii: index === 0 ? [22, 22, 6, 6]
                             : index === root.wifiNetworks.length - 1 ? [6, 6, 22, 22]
                             : [6, 6, 6, 6]
                        color: Theme.veilLow
                    }

                    Row {
                        x: 14
                        height: parent.height
                        spacing: 14

                        TritonIcon {
                            glyph: modelData.glyph || Icons.networkWifi
                            fill: modelData.connected === true
                            size: 24
                            color: modelData.connected ? Theme.primary : Theme.onsurface
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            TritonText {
                                text: modelData.name || ""
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 14
                                color: Theme.onsurface
                            }
                            TritonText {
                                text: modelData.status || ""
                                font.pixelSize: 12
                                color: Theme.onsurface
                                opacity: 0.75
                            }
                        }
                    }

                    TritonIcon {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: modelData.connected ? Icons.checkCircle : Icons.lock
                        fill: modelData.connected === true
                        size: modelData.connected ? 20 : 18
                        color: modelData.connected ? Theme.primary : Theme.onsurface
                        opacity: modelData.connected ? 1.0 : 0.7
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.networkClicked(index)
                    }
                }
            }

            Item { width: 1; height: 14 }

            Rectangle {
                width: parent.width
                height: 48
                radius: 24
                color: Theme.primaryContainer

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    TritonIcon {
                        glyph: Icons.openInNew
                        size: 20
                        color: Theme.onprimarycontainer
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TritonText {
                        text: "All network settings"
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 14
                        color: Theme.onprimarycontainer
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.allSettings()
                }
            }
        }
    }
}
