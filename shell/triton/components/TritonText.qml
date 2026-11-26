pragma ComponentBehavior: Bound

import QtQuick
import ".."

// The text atom. Every piece of text in the shell goes through this — never a
// raw Text item — so font resolution, rendering, and vertical centering are
// decided in exactly one place.
//
// Font families: the bundled fonts are static instances, so weight is part of
// the family name ("Jost SemiBold"). Qt weight matching is NOT used — it is
// unreliable across static instances. `weight` here selects the family suffix.
//
// Vertical centering: this item is a fixed-height box when `boxHeight` is set
// (the idiom inside bars and pills: bind to the parent's content height) and
// the glyphs are centered within it with AlignVCenter. Never rely on baseline
// arithmetic in calling code.

Text {
    id: root

    // Family selection by role, per the token type ramp.
    enum Family { Display, Ui, Mono }
    enum Weight { Regular, Medium, SemiBold }

    property int family: TritonText.Family.Ui
    property int weight: TritonText.Weight.Regular

    // When non-zero, the item takes exactly this height and glyphs center
    // within it. When zero, the item is exactly as tall as its text.
    property real boxHeight: 0

    readonly property string familyName: {
        switch (root.family) {
        case TritonText.Family.Display: return "Jost";
        case TritonText.Family.Mono: return "JetBrains Mono";
        default: return "Google Sans Flex";
        }
    }
    readonly property string weightSuffix: {
        switch (root.weight) {
        case TritonText.Weight.Medium: return " Medium";
        case TritonText.Weight.SemiBold: return " SemiBold";
        default: return "";
        }
    }

    font.family: root.familyName + (root.weight === TritonText.Weight.Regular ? "" : root.weightSuffix)
    font.pixelSize: 13
    color: Theme.onsurface
    renderType: Text.NativeRendering

    height: root.boxHeight > 0 ? root.boxHeight : implicitHeight
    verticalAlignment: Text.AlignVCenter
}
