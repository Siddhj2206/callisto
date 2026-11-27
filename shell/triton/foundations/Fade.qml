import QtQuick
import qs.tokens

// Opacity and other non-spatial values: `Behavior on opacity { Fade {} }`.
NumberAnimation {
    duration: Motion.fadeDefault
    easing.type: Easing.OutCubic
}
