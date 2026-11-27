import QtQuick
import QtQuick.Shapes
import qs.foundations
import qs.tokens

// A ring with a wavy outline, drawn clockwise from the top for `progress` of a
// turn over a faint full track.
Item {
    id: root

    property real size: Metrics.countdownRing
    property real progress: 1
    property string tone: "tertiary"
    property int lobes: 9

    readonly property Scheme scheme: Theming.of(root)
    readonly property real stroke: Metrics.progressHeight
    readonly property real wave: Metrics.ringStroke

    implicitWidth: size
    implicitHeight: size

    function outline(turn) {
        const middle = size / 2;
        const base = middle - stroke / 2 - wave;
        const steps = Math.max(2, Math.ceil(turn * lobes * 16));
        const points = [];
        for (let i = 0; i <= steps; i++) {
            const angle = turn * 2 * Math.PI * i / steps;
            const reach = base + wave * Math.cos(lobes * angle);
            points.push(Qt.point(middle + reach * Math.sin(angle), middle - reach * Math.cos(angle)));
        }
        return points;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.scheme.veilHi
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.outline(1) }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.progress > 0 ? root.scheme[root.tone] : "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.outline(Math.max(0, Math.min(1, root.progress))) }
        }
    }
}
