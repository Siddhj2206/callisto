import QtQuick
import qs
import qs.foundations
import qs.primitives
import qs.tokens

// Title row of a quick settings page. Anything declared inside sits at the end.
Item {
    id: root

    default property alias trailing: end.data
    property string title: ""
    property bool canGoBack: false

    signal back

    implicitHeight: Metrics.control

    IconButton {
        id: backButton
        visible: root.canGoBack
        variant: "veil"
        size: Metrics.control
        glyph: Icons.arrowBack
        label: "Back"
        onClicked: root.back()
    }
    AppText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.canGoBack ? backButton.right : parent.left
        anchors.leftMargin: root.canGoBack ? Metrics.rowGap : 0
        anchors.right: end.left
        role: "title"
        text: root.title
    }
    Row {
        id: end
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.panelGap
    }
}
