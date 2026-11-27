pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The capture tool over one frozen screen: drag a region, pick a window or
// take the whole screen. A pure view.
Item {
    id: root

    property url frozen
    property string mode: "region"
    property var windows: [] // [{ x, y, width, height, title }], topmost first
    property real scale0: 1 // physical pixels per logical one
    property string screenName: ""
    property int delay: 0
    property bool pointer: false
    property bool video: false
    property string audio: "" // "" | "mic" | "system"

    signal captured(rect area, bool copyOnly)
    signal modePicked(string mode)
    signal delayCycled
    signal pointerToggled
    signal videoToggled
    signal audioPicked(string audio)
    signal cancelled

    readonly property Scheme scheme: Theming.of(root)
    property rect selection: Qt.rect(0, 0, 0, 0)
    property int hovered: -1 // window under the pointer

    readonly property bool hasSelection: selection.width >= Metrics.minSelection && selection.height >= Metrics.minSelection
    // What would be captured now.
    readonly property rect area: mode === "screen" ? Qt.rect(0, 0, width, height)
        : mode === "window" ? (windows[hovered] ? Qt.rect(windows[hovered].x, windows[hovered].y, windows[hovered].width, windows[hovered].height) : Qt.rect(0, 0, 0, 0))
        : selection

    function reset() {
        selection = Qt.rect(0, 0, 0, 0);
        hovered = -1;
    }

    function take(copyOnly) {
        const left = Math.max(0, area.x), top = Math.max(0, area.y);
        const right = Math.min(width, area.x + area.width), bottom = Math.min(height, area.y + area.height);
        if (right - left >= Metrics.minSelection && bottom - top >= Metrics.minSelection)
            captured(Qt.rect(left, top, right - left, bottom - top), copyOnly);
    }

    function nudge(dx, dy) {
        if (mode !== "region" || !hasSelection)
            return;
        selection = Qt.rect(Math.max(0, Math.min(width - selection.width, selection.x + dx)),
            Math.max(0, Math.min(height - selection.height, selection.y + dy)), selection.width, selection.height);
    }

    function windowAt(x, y) {
        return windows.findIndex(w => x >= w.x && x < w.x + w.width && y >= w.y && y < w.y + w.height);
    }

    focus: true
    Keys.onPressed: event => {
        const step = event.modifiers & Qt.ControlModifier ? Metrics.dragThreshold : 1;
        if (event.key === Qt.Key_Escape)
            cancelled();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            take(event.modifiers & Qt.ShiftModifier);
        else if (event.key === Qt.Key_Space)
            modePicked(mode === "window" ? "region" : "window");
        else if (event.key === Qt.Key_1)
            modePicked("region");
        else if (event.key === Qt.Key_2)
            modePicked("window");
        else if (event.key === Qt.Key_3)
            modePicked("screen");
        else if (event.key === Qt.Key_V)
            videoToggled();
        else if (event.key === Qt.Key_Left)
            nudge(-step, 0);
        else if (event.key === Qt.Key_Right)
            nudge(step, 0);
        else if (event.key === Qt.Key_Up)
            nudge(0, -step);
        else if (event.key === Qt.Key_Down)
            nudge(0, step);
        else
            return;
        event.accepted = true;
    }

    Image {
        anchors.fill: parent
        source: root.frozen
        cache: false
    }

    // Everything outside the area, in shade.
    component Shade: Rectangle {
        color: root.scheme.backdrop
        opacity: root.mode === "screen" ? 0 : 1
    }
    Shade {
        width: root.width
        height: root.area.y
    }
    Shade {
        y: root.area.y + root.area.height
        width: root.width
        height: root.height - y
    }
    Shade {
        y: root.area.y
        width: root.area.x
        height: root.area.height
    }
    Shade {
        x: root.area.x + root.area.width
        y: root.area.y
        width: root.width - x
        height: root.area.height
    }

    Rectangle {
        visible: root.area.width > 0
        x: root.area.x
        y: root.area.y
        width: root.area.width
        height: root.area.height
        color: "transparent"
        border.width: Metrics.focusRing
        border.color: root.scheme.primary
    }

    // Drag a new region, or drag inside the current one to move it.
    MouseArea {
        id: drag
        property point from
        property rect original
        property bool moving: false

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.mode === "region" ? Qt.CrossCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            from = Qt.point(mouse.x, mouse.y);
            original = root.selection;
            moving = root.hasSelection && mouse.x >= original.x && mouse.x < original.x + original.width
                && mouse.y >= original.y && mouse.y < original.y + original.height;
        }
        onPositionChanged: mouse => {
            if (root.mode === "window")
                root.hovered = root.windowAt(mouse.x, mouse.y);
            if (!pressed || root.mode !== "region")
                return;
            const x = Math.max(0, Math.min(root.width, mouse.x)), y = Math.max(0, Math.min(root.height, mouse.y));
            if (moving)
                root.selection = Qt.rect(Math.max(0, Math.min(root.width - original.width, original.x + x - from.x)),
                    Math.max(0, Math.min(root.height - original.height, original.y + y - from.y)), original.width, original.height);
            else
                root.selection = Qt.rect(Math.min(from.x, x), Math.min(from.y, y), Math.abs(x - from.x), Math.abs(y - from.y));
        }
        onClicked: mouse => {
            if (root.mode === "window") {
                root.hovered = root.windowAt(mouse.x, mouse.y);
                root.take(mouse.modifiers & Qt.ShiftModifier);
            } else if (root.mode === "screen") {
                root.take(mouse.modifiers & Qt.ShiftModifier);
            }
        }
    }

    // Size, or the window's name, by the area; inside the screen near edges.
    Material {
        visible: root.area.width > 0
        kind: "thick"
        width: label.implicitWidth + Metrics.buttonPad * 2
        height: Metrics.chipHeight
        radius: height / 2
        x: Math.max(0, Math.min(root.width - width, root.area.x))
        y: root.area.y >= height + Metrics.buttonGap ? root.area.y - height - Metrics.buttonGap
            : root.area.y + Metrics.buttonGap

        AppText {
            id: label
            anchors.centerIn: parent
            role: "labelSmall"
            tabular: true
            textFormat: Text.PlainText
            text: {
                const size = Math.round(root.area.width * root.scale0) + " × " + Math.round(root.area.height * root.scale0);
                if (root.mode === "window")
                    return (root.windows[root.hovered]?.title ?? "") + "  " + size;
                return root.mode === "screen" ? root.screenName + "  " + size : size;
            }
        }
    }

    Material {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Metrics.panelPad
        kind: "thick"
        width: hints.width + Metrics.panelPad * 2
        height: Metrics.hintHeight
        radius: height / 2

        Row {
            id: hints
            anchors.centerIn: parent
            spacing: Metrics.panelPad

            KeyHint {
                keys: ["Space"]
                text: "window"
            }
            KeyHint {
                keys: ["Enter"]
                text: root.video ? "record" : "capture"
            }
            KeyHint {
                keys: ["V"]
                text: root.video ? "picture" : "video"
            }
            KeyHint {
                visible: !root.video
                keys: ["Shift"]
                text: "copy only"
            }
            KeyHint {
                keys: ["Esc"]
                text: "cancel"
            }
        }
    }

    Material {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.panelPad
        kind: "thick"
        width: tools.width + Metrics.panelPad * 2
        height: Metrics.captureButton + Metrics.cardActions * 2
        radius: height / 2

        // Presses on the toolbar must not start a selection behind it.
        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: tools
            anchors.centerIn: parent
            spacing: Metrics.rowGap

            Repeater {
                model: [{ id: "region", label: "Region" }, { id: "window", label: "Window" }, { id: "screen", label: "Screen" }]

                Chip {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    selected: root.mode === modelData.id
                    activeFocusOnTab: false
                    onClicked: root.modePicked(modelData.id)
                }
            }
            Button {
                anchors.verticalCenter: parent.verticalCenter
                variant: "veil"
                glyph: Icons.timer
                text: root.delay === 0 ? "Off" : root.delay + " s"
                activeFocusOnTab: false
                onClicked: root.delayCycled()
            }
            IconButton {
                visible: !root.video
                anchors.verticalCenter: parent.verticalCenter
                variant: "veil"
                size: Metrics.buttonHeight
                glyph: Icons.mouse
                label: "Include the pointer"
                selected: root.pointer
                activeFocusOnTab: false
                onClicked: root.pointerToggled()
            }
            Repeater {
                model: root.video ? [{ id: "mic", glyph: Icons.mic, label: "Record the microphone" },
                    { id: "system", glyph: Icons.volumeUp, label: "Record what the speakers play" }] : []

                IconButton {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    variant: "veil"
                    size: Metrics.buttonHeight
                    glyph: modelData.glyph
                    label: modelData.label
                    selected: root.audio === modelData.id
                    activeFocusOnTab: false
                    onClicked: root.audioPicked(selected ? "" : modelData.id)
                }
            }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                variant: "veil"
                size: Metrics.buttonHeight
                glyph: Icons.videocam
                label: "Record video"
                selected: root.video
                activeFocusOnTab: false
                onClicked: root.videoToggled()
            }
            Pressable {
                width: Metrics.captureButton
                height: width
                label: root.video ? "Record" : "Capture"
                activeFocusOnTab: false
                onClicked: root.take(false)

                WaveShape {
                    anchors.fill: parent
                    color: root.video ? root.scheme.errorContainer : root.scheme.primary

                    Icon {
                        anchors.centerIn: parent
                        glyph: root.video ? Icons.fiberManualRecord : Icons.photoCamera
                        fill: root.video
                        size: "lg"
                        tone: root.video ? "onerrorcontainer" : "onprimary"
                    }
                }
            }
        }
    }
}
