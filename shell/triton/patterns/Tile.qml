import QtQuick
import qs
import qs.foundations
import qs.tokens

// A quick setting. Off, a quiet pill; on, a filled rounded square. With
// `drillable`, the chevron end opens its page and the rest toggles.
Item {
    id: root

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool drillable: false

    signal toggled
    signal drilled

    readonly property Scheme scheme: Theming.of(root)
    readonly property string tone: checked ? "onprimary" : "onsurface"

    implicitHeight: Metrics.tileHeight

    Pressable {
        anchors.fill: parent
        radius: root.checked ? Metrics.tileOnRadius : height / 2
        fill: root.checked ? root.scheme.primary : root.scheme.veil
        ink: root.scheme[root.tone]
        label: root.title + (root.checked ? ", on" : ", off")
        onClicked: root.toggled()

        Icon {
            id: leading
            x: Metrics.tilePad
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            size: "lg"
            fill: root.checked
            tone: root.tone
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: leading.right
            anchors.leftMargin: Metrics.tileInnerGap
            anchors.right: parent.right
            anchors.rightMargin: root.drillable ? Metrics.tileDrill : Metrics.tilePad

            AppText {
                width: parent.width
                role: "label"
                tone: root.tone
                text: root.title
            }
            AppText {
                width: parent.width
                visible: root.subtitle !== ""
                role: "bodySmall"
                tone: root.checked ? root.tone : "onsurfacevariant"
                text: root.subtitle
            }
        }
    }

    Pressable {
        visible: root.drillable
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Metrics.tileDrill
        height: Metrics.tileDrill
        ink: root.scheme[root.tone]
        label: root.title + " options"
        onClicked: root.drilled()

        Icon {
            anchors.centerIn: parent
            glyph: Icons.chevronRight
            tone: root.tone
        }
    }
}
