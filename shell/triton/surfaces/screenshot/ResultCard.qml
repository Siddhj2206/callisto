import Quickshell.Widgets
import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// What was just captured, and what to do with it. A pure view.
Item {
    id: root

    property var result: null // { path, width, height, saved }

    signal viewRequested
    signal folderRequested
    signal deleteRequested

    readonly property Scheme scheme: Theming.of(root)
    readonly property bool hovered: pointer.hovered

    implicitWidth: Metrics.shotCard
    implicitHeight: column.implicitHeight + Metrics.panelPad * 2

    HoverHandler {
        id: pointer
    }

    Material {
        anchors.fill: parent
        kind: "thick"
        radius: Metrics.radiusPanelS
    }

    Column {
        id: column
        x: Metrics.panelPad
        y: Metrics.panelPad
        width: parent.width - Metrics.panelPad * 2
        spacing: Metrics.cardActions

        ClippingRectangle {
            width: parent.width
            height: Metrics.shotThumb
            radius: Metrics.radiusPanelS / 2
            color: root.scheme.surfaceContainerHighest

            Image {
                anchors.fill: parent
                source: root.result ? "file://" + root.result.path : ""
                sourceSize.width: Metrics.shotCard * 2
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }
        }
        AppText {
            width: parent.width
            role: "label"
            elide: Text.ElideMiddle
            textFormat: Text.PlainText
            text: root.result ? root.result.path.slice(root.result.path.lastIndexOf("/") + 1) : ""
        }
        AppText {
            role: "bodySmall"
            tone: "onsurfacevariant"
            text: !root.result ? "" : root.result.width + " × " + root.result.height
                + (root.result.saved ? " · saved and copied" : " · copied, not saved")
        }
        Row {
            spacing: Metrics.buttonGap

            Button {
                text: "Open"
                glyph: Icons.openInNew
                onClicked: root.viewRequested()
            }
            IconButton {
                visible: root.result?.saved ?? false
                variant: "veil"
                size: Metrics.buttonHeight
                glyph: Icons.folderOpen
                label: "Show in folder"
                onClicked: root.folderRequested()
            }
            IconButton {
                variant: "veil"
                size: Metrics.buttonHeight
                glyph: Icons.deleteIcon
                label: "Delete"
                onClicked: root.deleteRequested()
            }
        }
    }
}
