pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// Everything not yet dealt with, grouped by app.
Item {
    id: root

    property var groups: [] // [{ app, items }]
    property var describe: item => item // item -> NotificationCard entry
    property bool dnd: false

    signal dndToggled
    signal cleared(var items)
    signal activated(var item)
    signal dismissed(var item)
    signal actionTriggered(var item, string id)
    signal replied(var item, string text)

    property var folded: ({}) // app -> bool
    property var opened: ({}) // app -> bool, showing everything

    function set(map, key, value) {
        const next = Object.assign({}, map);
        next[key] = value;
        return next;
    }

    readonly property var apps: groups.map(g => g.app)
    function itemsOf(app) {
        return groups.find(g => g.app === app)?.items ?? [];
    }

    Item {
        id: header
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        height: Metrics.control

        AppText {
            anchors.verticalCenter: parent.verticalCenter
            role: "title"
            text: "Notifications"
        }
        Button {
            anchors.right: parent.right
            height: Metrics.control
            variant: root.dnd ? "filled" : "veil"
            glyph: Icons.bedtime
            text: "DND"
            label: root.dnd ? "Do not disturb, on" : "Do not disturb, off"
            onClicked: root.dndToggled()
        }
    }

    AppText {
        visible: root.groups.length === 0
        anchors.centerIn: parent
        role: "body"
        tone: "onsurfacevariant"
        text: "Nothing new"
    }

    Flickable {
        anchors.top: header.bottom
        anchors.topMargin: Metrics.panelGap
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.panelPad
        anchors.left: header.left
        anchors.right: header.right
        contentWidth: width
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: Metrics.panelGap

            // Keyed by app name so a group keeps its place and state.
            Repeater {
                model: ScriptModel { values: root.apps }

                NotificationGroup {
                    required property string modelData

                    width: list.width
                    app: modelData
                    items: root.itemsOf(modelData)
                    icon: items.length > 0 ? root.describe(items[0]).icon : ""
                    describe: root.describe
                    folded: root.folded[modelData] ?? false
                    showAll: root.opened[modelData] ?? false
                    onFoldToggled: root.folded = root.set(root.folded, modelData, !folded)
                    onShowAllRequested: root.opened = root.set(root.opened, modelData, true)
                    onCleared: root.cleared(items)
                    onActivated: item => root.activated(item)
                    onDismissed: item => root.dismissed(item)
                    onActionTriggered: (item, id) => root.actionTriggered(item, id)
                    onReplied: (item, text) => root.replied(item, text)
                }
            }
        }
    }
}
