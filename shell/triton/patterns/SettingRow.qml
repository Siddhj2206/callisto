import QtQuick
import qs.foundations
import qs.tokens

// One setting in a connected group: what it is on the left, its control on the
// right (children), anything wider underneath (`below`). In a narrow window the
// control moves under the text. The ends of a group are rounder than its seams.
Item {
    id: root

    default property alias control: controls.data
    property alias below: extra.data
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property string tone: "onsurfacevariant" // of the subtitle
    property bool selected: false
    property bool clickable: false

    signal clicked

    readonly property bool settingRow: true
    readonly property var siblings: parent ? Array.from(parent.visibleChildren).filter(c => c.settingRow === true) : []
    readonly property real topRadius: siblings[0] === root ? Metrics.listOuter : Metrics.listInner
    readonly property real bottomRadius: siblings[siblings.length - 1] === root ? Metrics.listOuter : Metrics.listInner
    readonly property bool stacked: width < Metrics.settingsStack && controls.width > 0
    readonly property Scheme scheme: Theming.of(root)

    width: parent ? parent.width : implicitWidth
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
        height: Math.max(Metrics.rowHeight, words.height + Metrics.rowPad)
            + (root.stacked ? controls.height + Metrics.rowPad : 0)
        radius: Metrics.listOuter
        interactive: root.clickable
        label: root.title
        onClicked: root.clicked()
    }

    Icon {
        id: leading
        x: Metrics.rowPad
        y: words.y + words.height / 2 - height / 2
        visible: root.glyph !== ""
        glyph: root.glyph
        size: "lg"
        fill: root.selected
        tone: root.selected ? "primary" : "onsurface"
    }
    Column {
        id: words
        x: root.glyph !== "" ? leading.x + leading.width + Metrics.rowGap : Metrics.rowPad
        y: (root.stacked ? line.height - controls.height - Metrics.rowPad : line.height) / 2 - height / 2
        width: Math.max(0, (root.stacked || controls.width === 0 ? root.width : controls.x - Metrics.rowGap) - x - Metrics.rowPad / 2)

        AppText {
            width: parent.width
            role: "label"
            text: root.title
        }
        AppText {
            width: parent.width
            visible: root.subtitle !== ""
            role: "bodySmall"
            tone: root.tone
            wrapMode: Text.WordWrap
            text: root.subtitle
        }
    }
    Row {
        id: controls
        x: root.stacked ? words.x : root.width - width - Metrics.rowPad
        y: root.stacked ? line.height - height - Metrics.rowPad : (line.height - height) / 2
        spacing: Metrics.rowGap
    }
    Column {
        id: extra
        x: Metrics.rowPad
        y: line.height
        width: parent.width - Metrics.rowPad * 2
    }
}
