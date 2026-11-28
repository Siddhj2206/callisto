import QtQuick
import qs.foundations
import qs.primitives
import qs.tokens

// The frame of a settings page: it scrolls, and its column stops growing at a
// readable width.
Flickable {
    id: root

    default property alias content: column.data
    property string title: ""
    property string subtitle: ""

    contentWidth: width
    contentHeight: column.height + Metrics.settingsPad * 2
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    // Short of the ends, where the window's corners are round.
    ScrollBar {
        parent: root
        target: root
        anchors.topMargin: Metrics.radiusPanelS
        anchors.bottomMargin: Metrics.radiusPanelS
    }

    // Keep what the keyboard has reached in view.
    readonly property Item focused: Window.activeFocusItem
    onFocusedChanged: {
        for (let node = focused; node; node = node.parent) {
            if (node !== column)
                continue;
            const top = focused.mapToItem(contentItem, 0, 0).y;
            const bottom = top + focused.height;
            if (top < contentY)
                contentY = Math.max(0, top - Metrics.settingsPad);
            else if (bottom > contentY + height)
                contentY = bottom + Metrics.settingsPad - height;
        }
    }

    Column {
        id: column
        x: (root.width - width) / 2
        y: Metrics.settingsPad
        width: Math.min(Metrics.settingsContent, root.width - Metrics.settingsPad * 2)
        spacing: Metrics.panelPad

        Column {
            width: parent.width

            AppText {
                width: parent.width
                role: "headline"
                text: root.title
            }
            AppText {
                width: parent.width
                visible: root.subtitle !== ""
                tone: "onsurfacevariant"
                wrapMode: Text.WordWrap
                text: root.subtitle
            }
        }
    }
}
