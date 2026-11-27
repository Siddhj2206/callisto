import QtQuick
import qs
import qs.foundations
import qs.patterns
import qs.primitives
import qs.tokens

// The bar's looks, with no services: everything shown comes in as properties.
// Floating, it is two glass islands; pinned, one mica strip.
Item {
    id: root

    property bool pinned: false
    property int workspaceCount: 4
    property int activeWorkspace: 1
    property string appName: ""
    property string windowTitle: ""
    property string time: ""
    property string date: ""
    property alias networkGlyph: status.networkGlyph
    property alias volumeGlyph: status.volumeGlyph
    property alias batteryGlyph: status.batteryGlyph
    property alias batteryPercent: status.batteryPercent
    property alias batteryRing: status.batteryRing
    property alias statusState: status.health
    property bool unread: false
    property bool dnd: false
    property var media: null // the player to show in the middle, if any
    property bool background: false // there are background apps
    property bool backgroundOpen: false
    property alias micApp: privacy.micApp
    property alias micMuted: privacy.micMuted
    property alias video: privacy.video

    readonly property Item leftItem: left
    readonly property Item rightItem: right
    readonly property Item centreItem: centre
    readonly property bool hovered: leftHover.hovered || centreHover.hovered || rightHover.hovered || stripHover.hovered

    signal launcherRequested
    signal workspaceRequested(int number)
    signal statusRequested
    signal notificationsRequested
    signal volumeStepped(real steps)
    signal mediaToggled
    signal mediaNextRequested
    signal mediaPreviousRequested
    signal mediaRequested
    signal backgroundRequested

    implicitHeight: Metrics.barHeight

    Material {
        visible: root.pinned
        anchors.fill: parent
        kind: "mica"

        HoverHandler { id: stripHover }
    }

    Island {
        id: left
        docked: root.pinned
        x: root.pinned ? Metrics.barDockedStart : Metrics.barSide

        HoverHandler { id: leftHover }

        WaveButton {
            onClicked: root.launcherRequested()
        }
        Item {
            width: Metrics.barPad
            height: 1
        }
        Repeater {
            model: root.workspaceCount
            WorkspacePill {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                number: index + 1
                active: root.activeWorkspace === number
                onClicked: root.workspaceRequested(number)
            }
        }
        WindowTitle {
            visible: root.appName !== ""
            anchors.verticalCenter: parent.verticalCenter
            appName: root.appName
            title: root.windowTitle
        }
    }

    Island {
        id: centre
        visible: root.media !== null
        docked: root.pinned
        x: Math.round((root.width - width) / 2)

        HoverHandler { id: centreHover }

        MediaPill {
            player: root.media
            onToggleRequested: root.mediaToggled()
            onNextRequested: root.mediaNextRequested()
            onPreviousRequested: root.mediaPreviousRequested()
            onOpened: root.mediaRequested()
        }
    }

    Island {
        id: right
        docked: root.pinned
        x: root.width - width - (root.pinned ? Metrics.barDockedEnd : Metrics.barSide)

        HoverHandler { id: rightHover }

        PrivacyChips {
            id: privacy
            visible: active
        }
        IconButton {
            visible: root.background
            variant: root.backgroundOpen ? "tonal" : "standard"
            glyph: Icons.moreHoriz
            label: "Background apps"
            onClicked: root.backgroundRequested()
        }
        Clock {
            time: root.time
            date: root.date
        }
        StatusPill {
            id: status
            onClicked: root.statusRequested()
            onScrolled: steps => root.volumeStepped(steps)
        }
        IconButton {
            variant: "veil"
            label: root.dnd ? "Notifications, do not disturb" : "Notifications"
            glyph: root.dnd ? Icons.notificationsOff : Icons.notifications
            selected: root.dnd
            onClicked: root.notificationsRequested()

            Badge {
                visible: root.unread && !root.dnd
                x: parent.width - width - Metrics.badgeInset
                y: Metrics.badgeInset
            }
        }
    }
}
