pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// Every workspace as a ribbon of live windows. Click or arrows to go, drag a
// window to another ribbon, type to hand over to the launcher. A pure view.
Item {
    id: root

    property url wallpaper
    property var ribbons: [] // [{ id, active, windows }]
    property int row: 0
    property int column: 0

    signal activated(string address)
    signal workspaceRequested(int workspace)
    signal moveRequested(string address, int workspace)
    signal closeRequested(string address)
    signal typed(string text)
    signal searchRequested
    signal closed

    readonly property Scheme scheme: Theming.of(root)
    readonly property real ribbonHeight: Metrics.ribbonThumb + Metrics.panelPad * 2
    property var dragged: null // the window being carried
    property point pointer

    // Starts on the active workspace, on its most recent window.
    function reset() {
        dragged = null;
        row = Math.max(0, ribbons.findIndex(r => r.active));
        column = 0;
        list.positionViewAtIndex(row, ListView.Center);
    }

    function clamp() {
        row = Math.max(0, Math.min(row, ribbons.length - 1));
        column = Math.max(0, Math.min(column, (ribbons[row]?.windows.length ?? 1) - 1));
    }

    onRibbonsChanged: clamp()

    function moveRow(step) {
        row += step;
        column = 0;
        clamp();
    }

    function enter() {
        const ribbon = ribbons[row];
        if (!ribbon)
            return;
        const window = ribbon.windows[column];
        if (window)
            activated(window.address);
        else
            workspaceRequested(ribbon.id);
    }

    function dropAt(x, y) {
        const target = list.itemAt(list.contentX + x - list.x, list.contentY + y - list.y);
        if (dragged && target && target.ribbon.id !== dragged.workspace)
            moveRequested(dragged.address, target.ribbon.id);
        dragged = null;
    }

    focus: true
    Keys.onPressed: event => {
        const window = ribbons[row]?.windows[column];
        if (event.key === Qt.Key_Escape)
            closed();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            enter();
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
            moveRow(-1);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
            moveRow(1);
        else if (event.key === Qt.Key_Left)
            { column -= 1; clamp(); }
        else if (event.key === Qt.Key_Right)
            { column += 1; clamp(); }
        else if (event.key === Qt.Key_Delete && window)
            closeRequested(window.address);
        else if (event.text.trim() !== "" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            typed(event.text);
        else
            return;
        event.accepted = true;
    }

    SessionBackdrop {
        anchors.fill: parent
        source: root.wallpaper
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
        onWheel: wheel => root.moveRow(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    Pressable {
        id: search
        anchors.horizontalCenter: parent.horizontalCenter
        y: Metrics.panelPad
        width: Math.min(Metrics.overviewSearch, parent.width - Metrics.panelPad * 2)
        height: Metrics.lockField
        radius: height / 2
        fill: root.scheme.glass
        label: "Search"
        activeFocusOnTab: false
        onClicked: root.searchRequested()

        Row {
            x: Metrics.fieldPad
            anchors.verticalCenter: parent.verticalCenter
            spacing: Metrics.rowGap

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Icons.search
                tone: "onsurfacevariant"
            }
            AppText {
                anchors.verticalCenter: parent.verticalCenter
                tone: "onsurfacevariant"
                text: "Type to launch or jump to a window"
            }
        }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: Metrics.panelPad
        anchors.bottom: hints.top
        anchors.bottomMargin: Metrics.panelPad
        width: parent.width
        clip: true
        interactive: false
        spacing: Metrics.rowGap
        model: root.ribbons.length
        currentIndex: root.row
        preferredHighlightBegin: (height - root.ribbonHeight) / 2
        preferredHighlightEnd: (height + root.ribbonHeight) / 2
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: Motion.reduce ? 0 : Motion.fadeSlow

        delegate: Item {
            id: lane
            required property int index
            readonly property var ribbon: root.ribbons[index]
            readonly property bool current: index === root.row

            width: list.width
            height: root.ribbonHeight

            Rectangle {
                x: Metrics.ribbonLabel
                width: parent.width - x + radius
                height: parent.height
                radius: Metrics.radiusPanelM
                color: lane.current ? root.scheme.veil : "transparent"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.workspaceRequested(lane.ribbon.id)
                onWheel: wheel => root.moveRow(wheel.angleDelta.y > 0 ? -1 : 1)
            }

            Column {
                width: Metrics.ribbonLabel
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.buttonGap

                WaveShape {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Metrics.brandMark
                    height: width
                    color: lane.ribbon.active ? root.scheme.primary : root.scheme.surfaceContainerHighest

                    AppText {
                        anchors.centerIn: parent
                        role: "label"
                        tone: lane.ribbon.active ? "onprimary" : "onsurface"
                        text: lane.ribbon.id
                    }
                }
                AppText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    text: lane.ribbon.windows.length === 0 ? "Empty"
                        : lane.ribbon.windows.length === 1 ? "1 window" : lane.ribbon.windows.length + " windows"
                }
            }

            ListView {
                id: strip
                x: Metrics.ribbonLabel + Metrics.panelPad
                y: Metrics.panelPad
                width: parent.width - x
                height: Metrics.ribbonThumb
                orientation: ListView.Horizontal
                spacing: Metrics.rowGap
                clip: true
                interactive: false
                // By address: a changed title must not rebuild the tiles and
                // their live captures.
                model: ScriptModel { values: lane.ribbon.windows.map(w => w.address) }
                currentIndex: lane.current ? root.column : 0
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Motion.reduce ? 0 : Motion.fadeSlow

                delegate: Item {
                    id: tile
                    required property string modelData
                    required property int index
                    readonly property var win: lane.ribbon.windows.find(w => w.address === modelData) ?? ({})
                    readonly property bool selected: lane.current && index === root.column

                    width: Math.round(Metrics.ribbonThumb * Math.max(Metrics.aspectMin, Math.min(Metrics.aspectMax, (win.aspect ?? 1))))
                    height: Metrics.ribbonThumb
                    opacity: root.dragged?.address === modelData ? Theme.stateDimmed : 1

                    WindowPreview {
                        anchors.fill: parent
                        capture: tile.win.capture ?? null
                        icon: tile.win.icon ?? ""
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: Metrics.radiusPanelS / 2
                        color: "transparent"
                        border.width: tile.selected ? Metrics.focusRing : 0
                        border.color: root.scheme.primary
                    }
                    Material {
                        x: Metrics.buttonGap
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Metrics.buttonGap
                        kind: "thick"
                        width: Math.min(name.implicitWidth + Metrics.buttonPad * 2, tile.width - Metrics.buttonGap * 2)
                        height: Metrics.chipHeight
                        radius: height / 2

                        AppText {
                            id: name
                            anchors.verticalCenter: parent.verticalCenter
                            x: Metrics.buttonPad
                            width: parent.width - Metrics.buttonPad * 2
                            role: "labelSmall"
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            text: tile.win.title ?? ""
                        }
                    }

                    MouseArea {
                        id: grab
                        property point from
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        preventStealing: true
                        onWheel: wheel => root.moveRow(wheel.angleDelta.y > 0 ? -1 : 1)
                        onPressed: mouse => from = Qt.point(mouse.x, mouse.y)
                        onPositionChanged: mouse => {
                            if (!(pressedButtons & Qt.LeftButton))
                                return;
                            if (!root.dragged && Math.hypot(mouse.x - from.x, mouse.y - from.y) > Metrics.dragThreshold)
                                root.dragged = tile.win;
                            if (root.dragged)
                                root.pointer = mapToItem(root, mouse.x, mouse.y);
                        }
                        onReleased: mouse => {
                            if (root.dragged) {
                                const at = mapToItem(root, mouse.x, mouse.y);
                                root.dropAt(at.x, at.y);
                            } else if (mouse.button === Qt.MiddleButton) {
                                root.closeRequested(tile.modelData);
                            } else {
                                root.activated(tile.modelData);
                            }
                        }
                        onCanceled: root.dragged = null
                    }
                }
            }
        }
    }

    // What follows the pointer while a window is carried.
    WindowPreview {
        visible: root.dragged !== null
        x: root.pointer.x - width / 2
        y: root.pointer.y - height / 2
        width: Metrics.switcherCard
        height: Metrics.switcherThumb
        capture: root.dragged?.capture ?? null
        icon: root.dragged?.icon ?? ""
        live: false
    }

    Material {
        id: hints
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.panelPad
        width: keys.width + Metrics.panelPad * 2
        height: Metrics.hintHeight
        radius: height / 2

        Row {
            id: keys
            anchors.centerIn: parent
            spacing: Metrics.panelPad

            KeyHint {
                keys: ["↑", "↓"]
                text: "workspace"
            }
            KeyHint {
                keys: ["Enter"]
                text: "go"
            }
            KeyHint {
                keys: ["Del"]
                text: "close"
            }
            KeyHint {
                keys: ["Esc"]
                text: "back"
            }
        }
    }
}
