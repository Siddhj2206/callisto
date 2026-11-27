//@ pragma Env QS_NO_RELOAD_POPUP=1

// The login screen, a Quickshell instance of its own run for greetd.
// See configs/greeter/.
import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.greeter

ShellRoot {
    Fonts {}
    GreeterHost {}
}
