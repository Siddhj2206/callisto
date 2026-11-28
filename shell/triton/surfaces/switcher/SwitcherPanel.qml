pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The switcher: the selected window named above a row of window cards. A pure
// view; the compositor binds do the stepping, the keys here are the extras.
Item {
    id: root

    property var windows: [] // see WindowService.describe
    property int index: 0
    property real maxWidth: Metrics.switcherWidth

    signal picked(int index)
    signal activated(int index)
    signal stepped(int direction)
    signal committed
    signal cancelled
    signal closeRequested
    signal floatRequested

    readonly property var current: windows[index] ?? null
    readonly property Scheme scheme: Theming.of(root)
    readonly property real cards: windows.length * (Metrics.switcherCard + Metrics.listGap) - Metrics.listGap

    implicitWidth: Math.min(maxWidth, Math.max(Metrics.loginCard + Metrics.panelPad * 2, cards + Metrics.panelPad * 2,
        hints.implicitWidth + Metrics.panelPad * 2))
    implicitHeight: column.implicitHeight + Metrics.panelPad * 2

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            cancelled();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            committed();
        else if (event.key === Qt.Key_Left)
            stepped(-1);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
            stepped(1);
        else if (event.key === Qt.Key_Q)
            closeRequested();
        else if (event.key === Qt.Key_F)
            floatRequested();
        else
            return;
        event.accepted = true;
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt)
            committed();
    }

    Column {
        id: column
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        Item {
            width: parent.width
            height: heading.implicitHeight

            Column {
                id: heading
                width: parent.width - position.width - Metrics.panelPad

                AppText {
                    width: parent.width
                    role: "headline"
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: root.current?.title ?? ""
                }
                AppText {
                    width: parent.width
                    role: "bodySmall"
                    tone: "onsurfacevariant"
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: !root.current ? "" : "Workspace " + root.current.workspace + " · " + root.current.app
                        + (root.current.floating ? " · floating" : "")
                }
            }
            AppText {
                id: position
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                role: "bodySmall"
                tone: "onsurfacevariant"
                text: (root.index + 1) + " of " + root.windows.length
            }
        }

        ListView {
            id: row
            width: parent.width
            height: Metrics.switcherThumb + Metrics.resultRow
            orientation: ListView.Horizontal
            spacing: Metrics.listGap
            clip: true
            interactive: false
            model: root.windows
            currentIndex: root.index
            // Keeps the selection in the middle once the row overflows.
            preferredHighlightBegin: (width - Metrics.switcherCard) / 2
            preferredHighlightEnd: (width + Metrics.switcherCard) / 2
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: Motion.reduce ? 0 : Motion.fadeSlow

            delegate: Pressable {
                id: card
                required property var modelData
                required property int index
                readonly property bool selected: index === root.index

                width: Metrics.switcherCard
                height: row.height
                radius: Metrics.radiusPanelS / 2
                label: modelData.title
                fill: selected ? root.scheme.primaryContainer : "transparent"
                activeFocusOnTab: false
                onClicked: root.activated(index)

                WindowPreview {
                    x: Metrics.buttonGap
                    y: Metrics.buttonGap
                    width: parent.width - Metrics.buttonGap * 2
                    height: Metrics.switcherThumb
                    capture: card.modelData.capture
                    icon: card.modelData.icon
                }
                Row {
                    x: Metrics.buttonGap * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Metrics.buttonGap
                    width: parent.width - x * 2
                    spacing: Metrics.buttonGap

                    Avatar {
                        id: appIcon
                        size: Metrics.discSm
                        iconSize: Metrics.iconMd
                        source: card.modelData.icon
                        glyph: Icons.apps
                    }
                    AppText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - appIcon.width - parent.spacing
                        role: "labelSmall"
                        tone: card.selected ? "onprimarycontainer" : "onsurface"
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: card.modelData.title
                    }
                }
            }
        }

        Row {
            id: hints
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.panelPad

            KeyHint {
                keys: ["Tab"]
                text: "next"
            }
            KeyHint {
                keys: ["Q"]
                text: "close"
            }
            KeyHint {
                keys: ["F"]
                text: "float"
            }
            KeyHint {
                keys: ["Esc"]
                text: "cancel"
            }
        }
    }
}
