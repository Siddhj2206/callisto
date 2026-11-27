import Quickshell
import QtQuick
// Quickshell only registers the folders its entry file reaches, and the pages
// are loaded by name, so everything they use is imported here.
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.services
import qs.surfaces.bar
import qs.surfaces.clipboard
import qs.surfaces.greeter
import qs.surfaces.launcher
import qs.surfaces.lock
import qs.surfaces.media
import qs.surfaces.notifications
import qs.surfaces.osd
import qs.surfaces.overview
import qs.surfaces.power
import qs.surfaces.quicksettings
import qs.surfaces.screenshot
import qs.surfaces.settings
import qs.surfaces.switcher
import qs.surfaces.tray
import qs.surfaces.wallpaper
import qs.tokens

// The galleries: every component with sample data and no services, one page per
// file in gallery/. CALLISTO_GALLERY picks the page.
//   scripts/test-shell.sh --gallery power
ShellRoot {
    id: root

    readonly property string page: Quickshell.env("CALLISTO_GALLERY") || "controls"

    LazyLoader {
        active: true
        source: Qt.resolvedUrl("gallery/" + root.page + ".qml")
    }
}
