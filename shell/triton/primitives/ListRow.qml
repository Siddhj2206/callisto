import QtQuick
import qs.foundations
import qs.tokens

// One row of a connected list: the ends of the list are rounder than the
// seams between rows. Children appear below the row's main line.
Item {
    id: root

    default property alias content: extra.data
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property string trailingGlyph: ""
    property string trailingAction: "" // makes the trailing glyph a button, named this
    property bool selected: false
    property bool first: true
    property bool last: true

    signal clicked
    signal trailingClicked

    readonly property Scheme scheme: Theming.of(root)
    readonly property real topRadius: first ? Metrics.listOuter : Metrics.listInner
    readonly property real bottomRadius: last ? Metrics.listOuter : Metrics.listInner

    implicitHeight: line.height + (extra.childrenRect.height > 0 ? extra.childrenRect.height + Metrics.rowPad : 0)

    Rectangle {
        anchors.fill: parent
        color: root.scheme.veil
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius
    }

    Pressable {
        id: line
        width: parent.width
        height: Metrics.rowHeight
        radius: Metrics.listOuter
        label: root.title
        onClicked: root.clicked()

        Icon {
            id: leading
            x: Metrics.rowPad
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            size: "lg"
            fill: root.selected
            tone: root.selected ? "primary" : "onsurface"
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: leading.right
            anchors.leftMargin: Metrics.rowGap
            anchors.right: trailing.left
            anchors.rightMargin: Metrics.rowGap

            AppText {
                width: parent.width
                role: "label"
                text: root.title
            }
            AppText {
                width: parent.width
                visible: root.subtitle !== ""
                role: "bodySmall"
                tone: "onsurfacevariant"
                text: root.subtitle
            }
        }
        Icon {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: Metrics.rowPad
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailingGlyph !== "" && root.trailingAction === ""
            width: root.trailingAction !== "" ? Metrics.barSlot : pixels
            glyph: root.trailingGlyph
            fill: root.selected
            tone: root.selected ? "primary" : "onsurfacevariant"
        }
    }

    IconButton {
        visible: root.trailingAction !== ""
        anchors.right: parent.right
        anchors.rightMargin: Metrics.rowPad
        y: (line.height - height) / 2
        variant: "veil"
        glyph: root.trailingGlyph
        label: root.trailingAction
        onClicked: root.trailingClicked()
    }

    Item {
        id: extra
        x: Metrics.rowPad
        y: line.height
        width: parent.width - Metrics.rowPad * 2
        height: childrenRect.height
    }
}
