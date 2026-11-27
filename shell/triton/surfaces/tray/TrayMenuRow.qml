import QtQuick
import qs
import qs.foundations
import qs.tokens

// A line of a background app's menu, or a separator.
Item {
    id: root

    property var entry: null // QsMenuEntry

    signal chosen

    implicitHeight: entry?.isSeparator ? Metrics.barPad * 2 + 1 : Metrics.chipHeight

    Rectangle {
        visible: root.entry?.isSeparator ?? false
        anchors.verticalCenter: parent.verticalCenter
        x: Metrics.rowPad
        width: parent.width - Metrics.rowPad * 2
        height: 1
        color: Theming.of(root).outlineVariant
    }
    Pressable {
        visible: !(root.entry?.isSeparator ?? true)
        anchors.fill: parent
        radius: Metrics.listInner
        label: root.entry?.text ?? ""
        interactive: root.entry?.enabled ?? false
        opacity: interactive ? 1 : Theme.stateDimmed
        onClicked: root.chosen()

        AppText {
            x: Metrics.rowPad
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Metrics.rowPad * 2 - Metrics.rowGap - Metrics.iconSm
            role: "body"
            text: root.entry?.text ?? ""
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: Metrics.rowPad
            anchors.verticalCenter: parent.verticalCenter
            visible: glyph !== ""
            size: "sm"
            tone: "onsurfacevariant"
            glyph: !root.entry ? "" : root.entry.hasChildren ? Icons.chevronRight
                : root.entry.checkState === Qt.Checked ? Icons.check : ""
        }
    }
}
