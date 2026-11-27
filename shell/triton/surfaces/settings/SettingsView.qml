pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.services
import qs.tokens

// The Settings window's content: pages in a sidebar, one page beside it. In a
// narrow window the two take turns. Typing anywhere searches.
// Not a FocusScope: taking focus back from the search field must be possible.
Item {
    id: root

    property string page: "appearance"
    property bool browsing: false // narrow: the sidebar is up

    readonly property bool narrow: width < Metrics.settingsNarrow
    readonly property bool searching: search.text.trim() !== ""
    readonly property Scheme scheme: Theming.of(root)
    readonly property var files: ({
        network: "NetworkSettings", bluetooth: "BluetoothSettings", displays: "DisplaySettings",
        sound: "SoundSettings", keyboard: "KeyboardSettings", mouse: "MouseSettings", power: "PowerSettings",
        appearance: "AppearanceSettings", bar: "BarSettings", windows: "WindowSettings",
        notifications: "NotificationSettings", apps: "AppSettings", users: "UserSettings", about: "AboutSettings",
    })

    function show(name) {
        if (!files[name])
            return;
        page = name;
        browsing = false;
        search.text = "";
        root.forceActiveFocus();
    }

    function step(by) {
        const names = SettingsCatalog.pages.map(p => p.name);
        page = names[Math.max(0, Math.min(names.length - 1, names.indexOf(page) + by))];
    }

    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) {
            browsing = narrow;
            search.focusInput();
        } else if (event.key === Qt.Key_Escape) {
            if (searching)
                search.text = "";
            else if (narrow)
                browsing = true;
            root.forceActiveFocus();
        } else if (event.key === Qt.Key_Up && !searching) {
            step(-1);
        } else if (event.key === Qt.Key_Down && !searching) {
            step(1);
        } else if (event.text.trim() !== "" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            browsing = narrow;
            search.text += event.text;
            search.focusInput();
        } else {
            return;
        }
        event.accepted = true;
    }

    Material {
        id: sidebar
        kind: "mica"
        width: root.narrow ? root.width : Metrics.settingsSidebar
        height: parent.height
        visible: !root.narrow || root.browsing

        TextField {
            id: search
            x: Metrics.panelPad
            y: Metrics.panelPad
            width: parent.width - Metrics.panelPad * 2
            placeholder: "Search settings"
            onAccepted: {
                const first = SettingsCatalog.search(text)[0];
                if (first)
                    root.show(first.page);
            }
            onTextChanged: {
                if (root.narrow && text !== "")
                    root.browsing = false;
            }
        }

        Flickable {
            id: nav

            // The selected page stays in view when the keys move it.
            function reveal(item) {
                if (item.y < contentY)
                    contentY = item.y;
                else if (item.y + item.height > contentY + height)
                    contentY = item.y + item.height - height;
            }

            anchors.top: search.bottom
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.panelPad
            anchors.left: parent.left
            anchors.right: parent.right
            contentHeight: list.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: list
                width: parent.width

                Repeater {
                    model: SettingsCatalog.pages

                    Column {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool heads: index === 0 || SettingsCatalog.pages[index - 1].group !== modelData.group

                        width: list.width
                        readonly property bool current: root.page === modelData.name
                        onCurrentChanged: {
                            if (current)
                                nav.reveal(entry);
                        }

                        AppText {
                            visible: entry.heads
                            leftPadding: Metrics.rowPad
                            topPadding: entry.index === 0 ? 0 : Metrics.panelPad
                            bottomPadding: Metrics.cardActions
                            role: "labelSmall"
                            tone: "onsurfacevariant"
                            text: entry.modelData.group
                        }
                        SidebarItem {
                            glyph: entry.modelData.glyph
                            title: entry.modelData.title
                            selected: !root.narrow && !root.searching && root.page === entry.modelData.name
                            onClicked: root.show(entry.modelData.name)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        x: root.narrow ? 0 : sidebar.width
        width: root.width - x
        height: parent.height
        visible: !root.narrow || !root.browsing
        color: root.scheme.surface

        Loader {
            id: content
            anchors.fill: parent
            anchors.topMargin: root.narrow ? Metrics.control + Metrics.panelPad : 0
            sourceComponent: root.searching ? results : undefined
            source: root.searching ? "" : Qt.resolvedUrl(root.files[root.page] + ".qml")
        }
        IconButton {
            visible: root.narrow
            x: Metrics.panelPad
            y: Metrics.panelPad
            size: Metrics.control
            variant: "veil"
            glyph: Icons.arrowBack
            label: "All settings"
            onClicked: {
                search.text = "";
                root.browsing = true;
            }
        }
    }

    Component {
        id: results

        SearchResults {
            query: search.text
            onChosen: page => root.show(page)
        }
    }
}
