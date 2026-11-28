import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// The selected entry in full, and what can be done with it.
Item {
    id: root

    property var entry: null
    property string text: ""

    signal pasteRequested
    signal pinRequested
    signal deleteRequested

    readonly property Scheme scheme: Theming.of(root)
    readonly property string kind: entry?.kind ?? ""

    visible: entry !== null

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: caption.top
        anchors.bottomMargin: Metrics.panelGap
        radius: Metrics.listCardRadius
        color: root.scheme.veil
        clip: true

        ScreenImage {
            visible: root.kind === "image"
            anchors.fill: parent
            anchors.margins: Metrics.cardPad
            file: root.kind === "image" ? "file://" + root.entry.path : ""
            fillMode: Image.PreserveAspectFit
            cache: false
        }

        Column {
            visible: root.kind === "color"
            anchors.centerIn: parent
            spacing: Metrics.panelGap

            WaveShape {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Metrics.swatch
                height: width
                color: root.kind === "color" ? root.entry.title : "transparent"
            }
            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "title"
                text: root.entry?.title ?? ""
            }
        }

        Flickable {
            visible: root.kind === "text" || root.kind === "link"
            anchors.fill: parent
            anchors.margins: Metrics.cardPad
            contentHeight: body.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Text {
                id: body
                width: parent.width
                // Copied text is shown as it is, never interpreted.
                textFormat: Text.PlainText
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                text: root.text !== "" ? root.text : root.entry?.title ?? ""
                font.family: Typography.roles.body.family
                font.pixelSize: Typography.roles.body.size
                color: root.scheme.onsurface
            }
        }
    }

    AppText {
        id: caption
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: actions.top
        anchors.bottomMargin: Metrics.panelGap
        role: "bodySmall"
        tone: "onsurfacevariant"
        text: root.entry?.detail ?? ""
    }

    Row {
        id: actions
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        spacing: Metrics.cardActions

        Button {
            glyph: Icons.contentPaste
            text: "Paste"
            activeFocusOnTab: false
            onClicked: root.pasteRequested()
        }
        IconButton {
            size: Metrics.buttonHeight
            variant: "veil"
            glyph: Icons.pushPin
            selected: root.entry?.pinned ?? false
            label: selected ? "Unpin" : "Pin"
            activeFocusOnTab: false
            onClicked: root.pinRequested()
        }
        IconButton {
            size: Metrics.buttonHeight
            variant: "veil"
            glyph: Icons.deleteIcon
            label: "Delete"
            activeFocusOnTab: false
            onClicked: root.deleteRequested()
        }
    }
}
