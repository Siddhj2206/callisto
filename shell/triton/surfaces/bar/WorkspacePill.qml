import QtQuick
import qs.foundations
import qs.tokens

// A workspace number. The active one stretches into a filled pill.
Pressable {
    id: root

    required property int number
    property bool active: false

    readonly property Scheme scheme: Theming.of(root)

    label: "Workspace " + number
    implicitHeight: Metrics.workspaceSize
    implicitWidth: stretch.value
    fill: active ? scheme.primary : "transparent"
    ink: active ? scheme.onprimary : scheme.onsurface

    Spring {
        id: stretch
        to: root.active ? Metrics.workspaceActive : Metrics.workspaceSize
        token: Motion.spatialFast
    }

    AppText {
        anchors.centerIn: parent
        role: "workspace"
        tone: root.active ? "onprimary" : "onsurfacevariant"
        text: root.number
    }
}
