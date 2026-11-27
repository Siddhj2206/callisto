pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.foundations
import qs.surfaces.power
import qs.tokens

// The power menu with sample data: opened, on Restart with a note, and
// counting down.
// Run: scripts/test-shell.sh --gallery power
Scope {
    Fonts {}

    FloatingWindow {
        title: "Callisto power menu"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        ThemeScope {
            id: scope
            mode: "dark"
            anchors.fill: parent

            Grid {
                anchors.fill: parent
                columns: 2

                Repeater {
                    model: 3

                    Item {
                        id: band
                        required property int index
                        width: parent.width / 2
                        height: parent.height / 2
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Qt.resolvedUrl("assets/wallpaper-1646.jpg")
                            fillMode: Image.PreserveAspectCrop
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: scope.themeScheme.backdrop
                        }
                        PowerMenu {
                            anchors.fill: parent
                            greeting: "Good evening, Sid"
                            uptime: "Up 3 days, 4 hours"
                            note: "Backup is blocking shutdown: writing files"
                            footer: "neptuno · callisto"
                            Component.onCompleted: {
                                if (band.index === 1)
                                    current = 3;
                                // Set directly so that the countdown holds still.
                                if (band.index === 2) {
                                    current = 4;
                                    pending = 4;
                                    remaining = 0.7;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
