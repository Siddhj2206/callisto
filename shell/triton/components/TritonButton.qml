pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Filled/tonal/veil button (boards `.t-btn`): h40 radius 20, padding 24px,
// 600 14px label. Press morphs corners toward radius 12 — that spring is the
// one place buttons are allowed to move.
//
// Variants: filled (primary on primary), tonal (secondary-container), veil
// (translucent white — the only fill allowed directly on glass), text.

Rectangle {
    id: root

    enum Variant { Filled, Tonal, Veil, Text }

    property int variant: TritonButton.Variant.Filled
    property string text: ""
    // Optional leading icon.
    property string icon: ""
    // Content color override — veil buttons inside a tinted card (top hit)
    // take the card's on-color rather than onsurface. Empty string = default.
    property string contentOverride: ""

    signal clicked

    readonly property color resolvedContent: {
        if (root.contentOverride !== "")
            return root.contentOverride;
        switch (root.variant) {
        case TritonButton.Variant.Filled: return Theme.onprimary;
        case TritonButton.Variant.Tonal: return Theme.onsecondarycontainer;
        default: return Theme.onsurface;
        }
    }
    readonly property color resolvedFill: {
        switch (root.variant) {
        case TritonButton.Variant.Filled: return Theme.primary;
        case TritonButton.Variant.Tonal: return Theme.secondaryContainer;
        case TritonButton.Variant.Veil: return Theme.veil;
        default: return "transparent";
        }
    }

    height: 40
    width: row.implicitWidth + (root.variant === TritonButton.Variant.Text ? 28 : 48)
    radius: mouse.pressed ? 12 : 20
    color: root.resolvedFill

    Behavior on radius {
        NumberAnimation { duration: 120 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        TritonIcon {
            visible: root.icon !== ""
            glyph: root.icon
            size: 20
            color: root.resolvedContent
        }

        TritonText {
            text: root.text
            weight: TritonText.Weight.SemiBold
            font.pixelSize: 14
            color: root.resolvedContent
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
