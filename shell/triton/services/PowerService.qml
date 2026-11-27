pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// What the power menu says about the machine, and what its actions run.
Singleton {
    id: root

    property string userName: "" // stays empty on the live system
    property string hostName: ""
    property real uptimeSeconds: 0
    // logind "block" inhibitors on shutdown: [{ who, why }]
    property var blockers: []

    readonly property string firstName: {
        const name = userName.trim().split(/\s+/)[0] ?? "";
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function greeting() {
        const hour = new Date().getHours();
        const part = hour >= 5 && hour < 12 ? "morning" : hour >= 12 && hour < 18 ? "afternoon" : "evening";
        return "Good " + part + (firstName ? ", " + firstName : "");
    }

    function uptime() {
        const minutes = Math.floor(uptimeSeconds / 60);
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor(minutes / 60) % 24;
        const count = (n, unit) => n + " " + unit + (n === 1 ? "" : "s");
        if (days > 0)
            return "Up " + count(days, "day") + ", " + count(hours, "hour");
        if (hours > 0)
            return "Up " + count(hours, "hour") + ", " + count(minutes % 60, "minute");
        return "Up " + count(minutes, "minute");
    }

    readonly property string blockerNote: blockers.length === 0 ? ""
        : blockers.length > 1 ? blockers.length + " programs are blocking shutdown"
        : blockers[0].who + " is blocking shutdown: " + blockers[0].why

    function refresh() {
        uptimeFile.reload();
        inhibitors.running = true;
    }

    // Lock is the shell's own; the caller handles it.
    function perform(action) {
        const commands = {
            sleep: ["systemctl", "suspend"],
            // The session must be stopped through uwsm, never by exiting the
            // compositor, or units are torn down in the wrong order.
            logout: ["uwsm", "stop"],
            restart: ["systemctl", "reboot"],
            shutdown: ["systemctl", "poweroff"]
        };
        if (!commands[action])
            return;
        // A refusal (an inhibitor, policy) must not pass silently. logind only
        // says "access denied", so name what is blocking when something is.
        const reason = action === "restart" || action === "shutdown" ? blockerNote : "";
        Quickshell.execDetached(["sh", "-c",
            'why=$1; shift; out=$("$@" 2>&1) || notify-send -u critical "That did not work" "${why:-$out}"',
            "sh", reason, ...commands[action]]);
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text())
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostName = text().trim()
    }

    Process {
        running: true
        // The full name, or the login without one. The live system's account
        // is a placeholder, so it is not greeted by name.
        command: ["sh", "-c", '[ -d /run/live/medium ] && exit; name=$(getent passwd "$(id -u)" | cut -d: -f5 | cut -d, -f1); echo "${name:-$(id -un)}"']
        stdout: StdioCollector {
            onStreamFinished: root.userName = text.trim()
        }
    }

    Process {
        id: inhibitors
        command: ["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "ListInhibitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // (what, who, why, mode, uid, pid)
                    root.blockers = JSON.parse(text).data[0]
                        .filter(i => i[3] === "block" && i[0].split(":").includes("shutdown"))
                        .map(i => ({ who: i[1], why: i[2] }));
                } catch (e) {
                    root.blockers = [];
                }
            }
        }
    }
}
