import QtQuick
import QtQuick.Shapes
import qs
import qs.foundations
import qs.tokens

// Playback position: the played part is a wave, the rest a flat track. A click
// or drag asks to seek, where `seekable`.
Item {
    id: root

    property real value: 0 // 0 to 1
    property bool seekable: false

    signal seeked(real fraction)

    readonly property Scheme scheme: Theming.of(root)
    readonly property real played: Math.max(0, Math.min(1, value)) * width

    implicitHeight: Metrics.waveRow
    Accessible.role: Accessible.ProgressBar
    Accessible.name: Math.round(value * 100) + "%"

    function wave(length) {
        const points = [];
        const middle = height / 2;
        for (let x = 0; x < length; x += 2)
            points.push(Qt.point(x, middle + Metrics.waveAmplitude * Math.sin(x / Metrics.waveLength * 2 * Math.PI)));
        points.push(Qt.point(length, middle + Metrics.waveAmplitude * Math.sin(length / Metrics.waveLength * 2 * Math.PI)));
        return points;
    }

    Rectangle {
        x: root.played + Metrics.wavePlayed
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.width - x)
        height: Metrics.wavePlayed
        radius: height / 2
        color: root.scheme.veilHi
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.scheme.primary
            strokeWidth: Metrics.wavePlayed
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.wave(root.played) }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.seeked(mouse.x / width)
    }
}
