pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.services

// Turns a live notification into what NotificationCard draws. Called from
// bindings, so the card follows the app's updates.
Singleton {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function plain(markup) {
        return markup.replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&");
    }

    function age(ms) {
        const minutes = Math.floor((clock.date.getTime() - ms) / 60000);
        return minutes < 1 ? "now" : minutes < 60 ? minutes + " min"
            : minutes < 1440 ? Math.floor(minutes / 60) + " h" : Math.floor(minutes / 1440) + " d";
    }

    function source(name) {
        if (!name)
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        return name.includes(":/") ? name : Quickshell.iconPath(name, true);
    }

    function of(n) {
        const progress = n.hints["value"];
        return {
            title: n.summary || NotificationState.appOf(n),
            body: root.plain(n.body),
            time: root.age(NotificationState.arrived[n.id] ?? clock.date.getTime()),
            icon: root.source(n.appIcon || DesktopEntries.heuristicLookup(n.desktopEntry || n.appName)?.icon),
            picture: root.source(n.image),
            critical: n.urgency === NotificationUrgency.Critical,
            progress: progress === undefined ? -1 : Math.max(0, Math.min(100, Math.round(progress))),
            actions: n.actions.filter(a => a.identifier !== "default" && a.identifier !== "inline-reply")
                .map(a => ({ id: a.identifier, text: a.text })),
            replyable: n.hasInlineReply,
            replyHint: n.inlineReplyPlaceholder
        };
    }
}
