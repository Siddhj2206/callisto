pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.surfaces.bar
import qs.surfaces.media
import qs.surfaces.osd
import qs.tokens

// Media controls with sample players, dark over light.
// Run: scripts/shell.py media
Scope {
    id: shell

    function player(title, artist, source, playing) {
        return { trackTitle: title, trackArtist: artist, trackAlbum: "Looped", identity: source, trackArtUrl: "",
            isPlaying: playing, canGoNext: true, canGoPrevious: true, canSeek: true, lengthSupported: true,
            length: 268, shuffleSupported: true, shuffle: true, loopSupported: true, loopState: 0 };
    }

    readonly property var players: [
        player("Orbit", "Kiasmos", "Firefox", true),
        player("Weightless, a title much longer than the pill has room for", "Marconi Union", "Spotify", false),
        player("Episode 214", "Podcast", "mpv", false)
    ]

    Fonts {}

    FloatingWindow {
        title: "Callisto media"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        Column {
            anchors.fill: parent

            Repeater {
                model: ["dark", "light"]

                ThemeScope {
                    id: band
                    required property string modelData
                    mode: modelData
                    width: parent.width
                    height: parent.height / 2

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/wallpaper-1646.jpg")
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }

                    Column {
                        x: 20
                        y: 20
                        spacing: 20

                        Bar {
                            width: 1200
                            time: "21:41"
                            date: "Sat 21 Nov"
                            volumeGlyph: Icons.volumeUp
                            media: shell.players[0]
                        }
                        OsdPill {
                            kind: "track"
                            track: ({ title: "Orbit", artist: "Kiasmos", art: "", playing: true })
                        }
                        OsdPill {
                            kind: "battery"
                            value: 0.15
                            detail: "About 40 minutes left"
                        }
                        Material {
                            width: pill.implicitWidth + 16
                            height: Metrics.barHeight
                            radius: height / 2
                            MediaPill {
                                id: pill
                                anchors.centerIn: parent
                                player: shell.players[1]
                                wide: true
                            }
                        }
                    }

                    Material {
                        x: 1260
                        y: 20
                        width: Metrics.mediaWidth
                        height: card.implicitHeight + Metrics.panelPad * 2
                        radius: Metrics.radiusPanelM

                        PlayerCard {
                            id: card
                            x: Metrics.panelPad
                            y: Metrics.panelPad
                            width: parent.width - Metrics.panelPad * 2
                            player: shell.players[0]
                            others: shell.players
                            position: 102
                        }
                    }
                }
            }
        }
    }
}
