pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// The OSD surface: a narrow strip window anchored bottom-center, 48px above
// the screen edge (OSD board). It never takes focus and never blocks input —
// exclusion ignore, keyboard focus none, and the pill passes events through.

PanelWindow {
    id: root

    anchors { left: true; right: true; bottom: true }
    implicitHeight: 64 + 48
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: OsdState.visible

    // The OSD is informational — input passes through everywhere except the
    // pill itself (which carries exactly one interactive element: the
    // battery-low Saver button).
    mask: Region { item: osdPill }

    Osd {
        id: osdPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        variant: OsdState.variant
        value: OsdState.value
        icon: OsdState.icon
        fillIcon: OsdState.fillIcon
        text: OsdState.text
        subtext: OsdState.subtext
        trackTitle: OsdState.trackTitle
        trackArtist: OsdState.trackArtist
        batteryPercentText: OsdState.batteryPercentText
        batteryTimeText: OsdState.batteryTimeText
    }
}
