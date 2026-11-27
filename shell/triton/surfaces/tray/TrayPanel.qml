pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// The background apps grid, or one app's menu in its place.
Column {
    id: root

    property var apps: [] // [{title, tooltipTitle, id, icon, attention}]
    property string menuTitle: "" // set while a menu is showing
    property var entries: [] // [QsMenuEntry]

    signal activated(var app)
    signal menuRequested(var app)
    signal secondaryRequested(var app)
    signal entryChosen(var entry)
    signal backRequested

    spacing: Metrics.barPad

    Row {
        spacing: Metrics.barPad

        IconButton {
            visible: root.menuTitle !== ""
            glyph: Icons.arrowBack
            label: "Back"
            onClicked: root.backRequested()
        }
        AppText {
            height: Metrics.barSlot
            width: Math.min(implicitWidth, root.width - Metrics.barSlot * 2)
            leftPadding: Metrics.barPad
            role: "labelSmall"
            tone: "onsurfacevariant"
            text: root.menuTitle !== "" ? root.menuTitle : "BACKGROUND APPS"
        }
    }

    Grid {
        id: grid
        visible: root.menuTitle === ""
        width: parent.width
        columns: 3
        spacing: Metrics.barPad * 2

        Repeater {
            model: root.apps

            TrayTile {
                required property var modelData
                width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
                title: modelData.title || modelData.tooltipTitle || modelData.id
                icon: modelData.icon
                attention: modelData.attention ?? false
                onActivated: root.activated(modelData)
                onMenuRequested: root.menuRequested(modelData)
                onSecondaryRequested: root.secondaryRequested(modelData)
            }
        }
    }

    Column {
        visible: root.menuTitle !== ""
        width: parent.width

        Repeater {
            model: root.entries

            TrayMenuRow {
                required property var modelData
                width: parent.width
                entry: modelData
                onChosen: root.entryChosen(modelData)
            }
        }
    }
}
