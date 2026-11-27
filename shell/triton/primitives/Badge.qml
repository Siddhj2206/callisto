import QtQuick
import qs.foundations
import qs.tokens

// Attention dot, ringed in the color behind it.
Rectangle {
    id: root

    property color ringColor: Theming.of(root).surfaceContainerHigh

    width: Metrics.badge + Metrics.badgeRing * 2
    height: width
    radius: width / 2
    color: ringColor

    Rectangle {
        anchors.centerIn: parent
        width: Metrics.badge
        height: width
        radius: width / 2
        color: Theming.of(root).tertiary
    }
}
