import QtQuick
import qs
import qs.foundations
import qs.tokens

// One background app: its icon on a tile, its name under it.
Column {
    id: root

    property string title: ""
    property string icon: ""
    property bool attention: false

    signal activated
    signal menuRequested
    signal secondaryRequested

    readonly property Scheme scheme: Theming.of(root)

    spacing: Metrics.barPad

    Pressable {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Metrics.trayTile
        height: Metrics.trayTile
        radius: Metrics.trayRadius
        label: root.title
        fill: root.attention ? root.scheme.secondaryContainer : root.scheme.veil
        onClicked: root.activated()
        Keys.onMenuPressed: root.menuRequested()

        Image {
            id: image
            anchors.centerIn: parent
            width: Metrics.iconLg
            height: Metrics.iconLg
            sourceSize: Qt.size(width * 2, height * 2)
            source: root.icon
        }
        Icon {
            anchors.centerIn: parent
            visible: image.status !== Image.Ready
            glyph: Icons.apps
            size: "lg"
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton | Qt.MiddleButton
            onClicked: event => event.button === Qt.RightButton ? root.menuRequested() : root.secondaryRequested()
        }
    }
    AppText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        role: "bodySmall"
        text: root.title
    }
}
