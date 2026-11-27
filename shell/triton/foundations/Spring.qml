import QtQuick
import qs.tokens

// The one spring in the shell. Drive spatial properties (position, size,
// scale, radius) through it:
//
//   Spring { id: grow; to: open ? 200 : 40; token: Motion.spatialFast }
//   width: grow.value
//
// It integrates the damped oscillator exactly each frame, so retargeting
// mid-flight keeps the velocity. The first value is set without animating.
// Colors and opacity use Fade / ColorFade instead.
QtObject {
    id: root

    property real to: 0
    property var token: Motion.spatialDefault // [stiffness, damping ratio]
    property real epsilon: 0.1
    property real value: 0
    property real velocity: 0
    readonly property bool running: clock.running

    property bool ready: false

    function snap(v) {
        clock.stop();
        velocity = 0;
        value = v;
    }

    onToChanged: {
        if (!ready || Motion.reduce)
            snap(to);
        else
            clock.start();
    }

    Component.onCompleted: {
        snap(to);
        ready = true;
    }

    function step(dt) {
        const k = token[0], z = token[1];
        const w = Math.sqrt(k);
        const x = value - to;
        const v = velocity;
        let nx, nv;
        if (z < 1) {
            const wd = w * Math.sqrt(1 - z * z);
            const decay = Math.exp(-z * w * dt);
            const b = (v + z * w * x) / wd;
            const cos = Math.cos(wd * dt), sin = Math.sin(wd * dt);
            nx = decay * (x * cos + b * sin);
            nv = decay * (cos * (b * wd - z * w * x) - sin * (x * wd + z * w * b));
        } else {
            const decay = Math.exp(-w * dt);
            const c = v + w * x;
            nx = (x + c * dt) * decay;
            nv = (v - w * c * dt) * decay;
        }
        if (Math.abs(nx) < epsilon && Math.abs(nv) < epsilon * 10) {
            snap(to);
        } else {
            velocity = nv;
            value = to + nx;
        }
    }

    property FrameAnimation clock: FrameAnimation {
        // A stalled frame must not fling the spring.
        onTriggered: root.step(Math.min(frameTime, 0.064))
    }
}
