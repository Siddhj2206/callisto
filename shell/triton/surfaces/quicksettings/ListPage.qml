import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// The shape shared by the drill-in pages: header with an optional switch, a
// list that scrolls when long (or a line saying why it is empty), and a button
// to the matching Settings page.
Column {
    id: root

    default property alias rows: list.data
    property string title: ""
    property bool hasSwitch: false
    property bool checked: false
    property string emptyText: ""
    property bool empty: false
    property string settingsText: ""

    signal back
    signal toggled(bool checked)
    signal settingsRequested

    spacing: Metrics.panelGap

    PageHeader {
        width: parent.width
        title: root.title
        canGoBack: true
        onBack: root.back()

        Switch {
            visible: root.hasSwitch
            checked: root.checked
            label: root.title
            onToggled: on => root.toggled(on)
        }
    }

    AppText {
        visible: root.empty
        width: parent.width
        height: Metrics.rowHeight
        horizontalAlignment: Text.AlignHCenter
        role: "body"
        tone: "onsurfacevariant"
        text: root.emptyText
    }

    Flickable {
        visible: !root.empty
        width: parent.width
        height: Math.min(list.implicitHeight, Metrics.listMax)
        contentWidth: width
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: list
            width: parent.width
            spacing: Metrics.listGap
        }
    }

    Button {
        width: parent.width
        variant: "container"
        glyph: Icons.openInNew
        text: root.settingsText
        onClicked: root.settingsRequested()
    }
}
