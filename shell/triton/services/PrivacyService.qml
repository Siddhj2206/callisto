pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Who is listening or watching right now, read from PipeWire's links.
Singleton {
    id: root

    readonly property var links: Pipewire.linkGroups.values.filter(l => l.source && l.target)

    function is(node, type) {
        return (node.type & type) === type;
    }

    // An app recording from a microphone. Level meters, which volume tools
    // open on every device, do not count, and neither do speaker monitors.
    readonly property var micLinks: links.filter(l => is(l.source, PwNodeType.AudioSource)
        && is(l.target, PwNodeType.AudioInStream) && l.target.properties["stream.monitor"] !== "true")
    readonly property var videoLinks: links.filter(l => is(l.source, PwNodeType.Video))

    readonly property string micApp: micLinks.length > 0 ? name(micLinks[0].target) : ""
    readonly property bool micMuted: micLinks[0]?.source.audio?.muted ?? false
    // A camera is a device; anything else sending video is a screen share.
    readonly property string video: videoLinks.length === 0 ? ""
        : videoLinks.some(l => !!l.source.properties["device.api"]) ? "camera" : "screen"

    function name(node) {
        // Our own screen recorder names itself with a number.
        if ((node.properties["application.name"] ?? "").startsWith("wf-recorder"))
            return "Microphone";
        return node.properties["application.name"] || node.description || node.name || "Microphone";
    }

    // Properties are only filled in for tracked nodes.
    PwObjectTracker {
        objects: root.links.reduce((all, l) => all.concat([l.source, l.target]), [])
    }
}
