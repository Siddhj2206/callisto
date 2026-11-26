pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// Section label inside a panel (.sec): primary, semibold 14, letterspaced.

TritonText {
    property string label: ""
    text: label
    weight: TritonText.Weight.SemiBold
    font.pixelSize: 14
    font.letterSpacing: 0.3
    color: Theme.primary
}
