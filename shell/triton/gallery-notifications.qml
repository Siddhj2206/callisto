pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs
import qs.foundations
import qs.surfaces.notifications
import qs.tokens

// Toasts and the notification center with sample data, dark and light.
// Headless: scripts/test-shell.sh --entry gallery-notifications.qml
ShellRoot {
    id: shell

    function entry(extra) {
        return Object.assign({
            title: "", body: "", time: "now", icon: "", picture: "", critical: false,
            progress: -1, actions: [], replyable: false, replyHint: ""
        }, extra);
    }

    readonly property var toasts: [
        entry({ title: "Mia", body: "Thinking ramen at 1, you in?", replyable: true }),
        entry({ title: "Copying 3 files", body: "To Backups", time: "1 min", progress: 58, actions: [{ id: "c", text: "Cancel" }] }),
        entry({ title: "Battery low", body: "9% remaining. Plug in soon, or switch on the power saver to last a little longer than that.", critical: true,
                actions: [{ id: "s", text: "Power saver" }, { id: "d", text: "Dismiss" }] }),
        entry({ title: "A title far too long to fit beside the time it arrived at", body: "Short." }),
        entry({ title: "Five" }), entry({ title: "Six" })
    ]
    readonly property var groups: [
        { app: "Chat", items: [
            entry({ title: "Mia", body: "Thinking ramen at 1, you in?" }),
            entry({ title: "Dev group", body: "Priya: build is green again", time: "12 min" }),
            entry({ title: "Sam", body: "ok", time: "20 min" }),
            entry({ title: "Kit", body: "later", time: "30 min" })
        ] },
        { app: "Calendar", items: [entry({ title: "Design review", body: "Tomorrow, 10:00 · Room 4", time: "1 h" })] }
    ]

    Fonts {}

    FloatingWindow {
        title: "Callisto notifications"
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#101014"

        Row {
            anchors.fill: parent

            Repeater {
                model: ["dark", "light"]

                ThemeScope {
                    id: band
                    required property string modelData
                    mode: modelData
                    width: parent.width / 2
                    height: parent.height

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("board-wallpaper-1646.jpg")
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }

                    ToastStack {
                        x: 24
                        y: 24
                        width: Metrics.panelWidth
                        items: shell.toasts
                        timeout: 600000
                    }

                    Material {
                        x: 48 + Metrics.panelWidth
                        y: 24
                        width: Metrics.centerWidth
                        height: 620
                        radius: Metrics.radiusPanelS

                        NotificationCenter {
                            anchors.fill: parent
                            groups: shell.groups
                        }
                    }
                }
            }
        }
    }
}
