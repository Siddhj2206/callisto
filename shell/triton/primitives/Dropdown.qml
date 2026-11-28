pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.tokens

// A field showing one choice of many, with the rest in a menu below it (above,
// when there is no room). `options` is [{ value, label }]. By keyboard: Enter or
// Space opens, the arrows move, Enter picks, Escape closes.
Pressable {
    id: root

    property var options: []
    property var current
    property string name: "" // what is being chosen, for screen readers

    signal chosen(var value)

    readonly property Scheme scheme: Theming.of(root)
    readonly property int index: options.findIndex(o => o.value === current)
    readonly property string text: options[index]?.label ?? ""

    property bool open: false
    // Where the menu is drawn: above everything, but in the same color scheme.
    property Item host: null
    property real menuX: 0
    property real menuY: 0
    property bool upward: false
    // Who gets the keyboard back: with a mouse, not this field and its ring.
    property Item before: null

    function show() {
        let item = root;
        while (item.parent && item.themeScheme === undefined)
            item = item.parent;
        host = item;
        const at = root.mapToItem(item, 0, 0);
        const below = at.y + root.height + Metrics.cardActions;
        upward = below + menu.height > item.height && at.y - menu.height - Metrics.cardActions >= 0;
        menuX = at.x;
        menuY = upward ? at.y - menu.height - Metrics.cardActions : below;
        list.currentIndex = Math.max(0, index);
        before = root.Window.activeFocusItem;
        open = true;
        list.positionViewAtIndex(list.currentIndex, ListView.Center);
        keys.forceActiveFocus();
    }

    function close() {
        open = false;
        (before ?? root).forceActiveFocus();
    }

    function pick(value) {
        close();
        if (value !== current)
            chosen(value);
    }

    implicitWidth: Metrics.settingsControl
    implicitHeight: Metrics.control
    fill: scheme.veil
    ink: scheme.onsurface
    label: name !== "" ? name + ": " + text : text
    Accessible.role: Accessible.ComboBox
    onClicked: open ? close() : show()

    AppText {
        x: Metrics.rowPad
        anchors.verticalCenter: parent.verticalCenter
        width: arrow.x - x - Metrics.buttonGap
        role: "label"
        text: root.text
    }
    Icon {
        id: arrow
        anchors.right: parent.right
        anchors.rightMargin: Metrics.rowPad
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.open ? Icons.expandLess : Icons.expandMore
        tone: "onsurfacevariant"
    }

    Item {
        id: overlay
        parent: root.host ?? root
        anchors.fill: parent
        z: 1
        visible: root.host !== null && presence.mapped
        onWidthChanged: root.open = false
        onHeightChanged: root.open = false

        // A press elsewhere closes the menu and does nothing more.
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onPressed: root.close()
            onWheel: wheel => wheel.accepted = true
        }

        Presence {
            id: presence
            show: root.open
            fromScale: Metrics.enterScale
            transformOrigin: root.upward ? Item.Bottom : Item.Top
            x: root.menuX
            y: root.menuY
            width: root.width
            height: menu.height

            Rectangle {
                id: menu
                width: parent.width
                height: Math.min(Metrics.menuHeight, root.options.length * Metrics.buttonHeight)
                    + Metrics.cardActions * 2
                radius: Metrics.radiusPanelS
                // Solid: nothing blurs what is behind inside a window.
                color: root.scheme.surfaceContainerHigh
                border.width: 1
                border.color: root.scheme.outlineVariant

                // Takes the keys, so that no row draws a focus ring of its own:
                // the highlight shows where one is.
                Item {
                    id: keys
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down)
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                        else if (event.key === Qt.Key_Up)
                            list.currentIndex = Math.max(0, list.currentIndex - 1);
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                            root.pick(root.options[list.currentIndex].value);
                        else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Tab)
                            root.close();
                        event.accepted = true;
                    }
                }
                // Presses between the rows stay in the menu.
                MouseArea {
                    anchors.fill: parent
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: Metrics.cardActions
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false
                    model: root.options

                    delegate: Pressable {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: modelData.value === root.current
                        readonly property bool pointed: ListView.isCurrentItem

                        width: list.width - (list.contentHeight > list.height ? Metrics.scrollbarHit : 0)
                        height: Metrics.buttonHeight
                        activeFocusOnTab: false
                        fill: pointed ? root.scheme.veil : "transparent"
                        ink: root.scheme.primary
                        label: modelData.label
                        onClicked: root.pick(modelData.value)

                        AppText {
                            x: Metrics.rowPad
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Metrics.rowPad * 2 - Metrics.iconMd - Metrics.buttonGap
                            role: "label"
                            tone: row.selected ? "primary" : "onsurface"
                            text: row.modelData.label
                        }
                        Icon {
                            visible: row.selected
                            anchors.right: parent.right
                            anchors.rightMargin: Metrics.rowPad
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: Icons.check
                            tone: "primary"
                        }
                    }

                    ScrollBar {
                        parent: list
                        target: list
                    }
                }
            }
        }
    }
}
