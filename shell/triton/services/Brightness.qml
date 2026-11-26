pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Non-visual backlight service singleton.
//
// Reads /sys/class/backlight/<device>/{brightness,max_brightness} and writes
// through brightnessctl (users cannot write sysfs backlight directly; the
// brightnessctl binary carries the needed privilege mechanism on the ISO).
//
// Event strategy, documented per shell-conventions rule 6 (no polling):
// sysfs backlight entries are not real files with inotify write semantics
// on every kernel, so FileView.watchChanges is a best-effort fast path.
// We therefore run a refresh Timer at 1 Hz, but ONLY while `live` is true.
// The OSD sets `live` when its surfaces exist; the rest of the time this
// service is fully idle. This is the on-demand 1 Hz fallback explicitly
// permitted for sysfs backlight.
//
// Degrades to `available: false` on machines with no backlight (VMs, most
// desktops), in which case all methods are no-ops and nothing should render.
Singleton {
    id: root

    // Fraction of max brightness applied per up()/down() call.
    readonly property real step: 0.05

    // Set true by consumers that need live updates (the OSD surface).
    // While false, nothing polls and only initial discovery has run.
    property bool live: false

    readonly property bool available: device !== ""
    property string device: ""
    property int rawBrightness: 0
    property int rawMaxBrightness: 0

    // 0..1 or null when no backlight exists.
    readonly property var brightness: (root.available && rawMaxBrightness > 0)
        ? rawBrightness / rawMaxBrightness : null

    signal brightnessInteracted(real brightness)

    property bool _primed: false

    onBrightnessChanged: {
        if (root.brightness === null) return;
        if (root._primed) {
            root.brightnessInteracted(root.brightness);
        } else {
            root._primed = true;
        }
    }

    // ---- device discovery (one async scan at startup, rescan on demand) ----

    Process {
        id: scanProc
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                root.device = dev;
                root._primed = false;
            }
        }
    }

    // ---- reads ----

    FileView {
        id: brightnessFile
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: true
        printErrors: false
        onLoaded: root._ingest()
        onFileChanged: this.reload()
    }

    FileView {
        id: maxBrightnessFile
        path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
        printErrors: false
        onLoaded: root._ingestMax()
    }

    function _ingest() {
        const v = parseInt(brightnessFile.text().trim());
        if (!isNaN(v)) root.rawBrightness = v;
    }

    function _ingestMax() {
        const v = parseInt(maxBrightnessFile.text().trim());
        if (!isNaN(v) && v > 0) root.rawMaxBrightness = v;
    }

    // On-demand 1 Hz refresh — running only while `live` is set by a consumer.
    Timer {
        interval: 1000
        repeat: true
        running: root.live && root.available
        onTriggered: brightnessFile.reload()
    }

    // Fast read-back after our own writes: brightnessctl applies the write
    // synchronously, but execDetached is async, so re-read shortly after
    // instead of waiting for the 1 Hz tick. Two passes catch slow drivers.
    Timer {
        id: postWriteFast
        interval: 120
        onTriggered: brightnessFile.reload()
    }
    Timer {
        id: postWriteSlow
        interval: 450
        onTriggered: brightnessFile.reload()
    }

    function _scheduleReadback() {
        postWriteFast.restart();
        postWriteSlow.restart();
    }

    // ---- writes ----

    function _set(percent) {
        if (!root.available) return;
        const clamped = Math.max(1, Math.min(100, Math.round(percent)));
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "set", clamped + "%"]);
        root._scheduleReadback();
    }

    function up() {
        if (!root.available) return;
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "set", "+" + Math.round(root.step * 100) + "%"]);
        root._scheduleReadback();
    }

    function down() {
        if (!root.available) return;
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "set", Math.round(root.step * 100) + "%-"]);
        root._scheduleReadback();
    }

    function setBrightness(fraction) {
        root._set(fraction * 100);
    }
}
