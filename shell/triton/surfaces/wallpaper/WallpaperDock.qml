pragma ComponentBehavior: Bound

import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The shelf of wallpapers along the bottom. A pure view: browsing asks for a
// preview, choosing asks to apply.
Item {
    id: root

    property var items: [] // [{ path, name, source }]
    property string current: "" // the committed wallpaper
    property string source: "system"
    property int selection: 0
    property bool onLockScreen: true

    signal browsed(string path)
    signal chosen(string path)
    signal folderRequested
    signal lockToggled(bool on)
    signal closed

    readonly property Scheme scheme: Theming.of(root)
    readonly property var shelf: items.filter(i => i.source === source)

    implicitHeight: column.implicitHeight + Metrics.panelPad * 2

    // Opens on the wallpaper in use.
    function reveal() {
        const found = items.find(i => i.path === current);
        source = found?.source ?? "system";
        selection = Math.max(0, items.filter(i => i.source === source).findIndex(i => i.path === current));
    }

    function select(index) {
        if (shelf.length === 0)
            return;
        selection = (index + shelf.length) % shelf.length;
        browsed(shelf[selection].path);
    }

    function show(name) {
        source = name;
        selection = 0;
        if (shelf.length > 0)
            browsed(shelf[0].path);
    }

    function accept() {
        if (shelf[selection])
            chosen(shelf[selection].path);
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            closed();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            accept();
        else if (event.key === Qt.Key_Left)
            select(selection - 1);
        else if (event.key === Qt.Key_Right)
            select(selection + 1);
        else if (event.key === Qt.Key_R)
            select(Math.floor(Math.random() * shelf.length));
        else if (event.key === Qt.Key_1)
            show("system");
        else if (event.key === Qt.Key_2)
            show("pictures");
        else
            return;
        event.accepted = true;
    }

    Column {
        id: column
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        Item {
            width: parent.width
            height: Metrics.control

            Row {
                spacing: Metrics.buttonGap

                Chip {
                    text: "Callisto"
                    selected: root.source === "system"
                    onClicked: root.show("system")
                }
                Chip {
                    text: "Pictures"
                    selected: root.source === "pictures"
                    onClicked: root.show("pictures")
                }
            }
            Row {
                anchors.right: parent.right
                spacing: Metrics.rowGap

                AppText {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    text: "Also on the lock screen"
                }
                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Also on the lock screen"
                    checked: root.onLockScreen
                    onToggled: on => root.lockToggled(on)
                }
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    variant: "veil"
                    glyph: Icons.folderOpen
                    text: "Wallpapers folder"
                    onClicked: root.folderRequested()
                }
            }
        }

        Item {
            width: parent.width
            height: Metrics.wallThumbHeight + Metrics.resultRow

            AppText {
                visible: root.shelf.length === 0
                anchors.centerIn: parent
                tone: "onsurfacevariant"
                text: root.source === "pictures" ? "No pictures yet. Put images in the Wallpapers folder." : "No wallpapers installed."
            }

            ListView {
                id: list
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: Metrics.rowGap
                clip: true
                model: root.shelf
                currentIndex: root.selection
                preferredHighlightBegin: (width - Metrics.wallThumbWidth) / 2
                preferredHighlightEnd: (width + Metrics.wallThumbWidth) / 2
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: Motion.reduce ? 0 : Motion.fadeSlow

                delegate: Pressable {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.selection

                    width: Metrics.wallThumbWidth
                    height: list.height
                    radius: Metrics.radiusPanelS / 2
                    label: modelData.name
                    activeFocusOnTab: false
                    // One click tries it on, a second one keeps it.
                    onClicked: selected ? root.accept() : root.select(index)

                    ClippingRectangle {
                        id: thumb
                        width: parent.width
                        height: Metrics.wallThumbHeight
                        radius: Metrics.radiusPanelS / 2
                        color: root.scheme.surfaceContainerHighest

                        Image {
                            anchors.fill: parent
                            source: "file://" + card.modelData.path
                            sourceSize.width: Metrics.wallThumbWidth * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    Rectangle {
                        anchors.fill: thumb
                        radius: thumb.radius
                        color: "transparent"
                        border.width: card.selected ? Metrics.focusRing : 0
                        border.color: root.scheme.primary
                    }
                    WaveShape {
                        visible: card.modelData.path === root.current
                        anchors.right: thumb.right
                        anchors.top: thumb.top
                        anchors.margins: Metrics.buttonGap
                        width: Metrics.discSm
                        height: width

                        Icon {
                            anchors.centerIn: parent
                            glyph: Icons.check
                            size: "sm"
                            tone: "onprimary"
                        }
                    }
                    AppText {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Metrics.buttonGap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        role: "labelSmall"
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: card.modelData.name
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.panelPad

            KeyHint {
                keys: ["←", "→"]
                text: "browse"
            }
            KeyHint {
                keys: ["Enter"]
                text: "set"
            }
            KeyHint {
                keys: ["R"]
                text: "random"
            }
            KeyHint {
                keys: ["Esc"]
                text: "put it back"
            }
        }
    }
}
