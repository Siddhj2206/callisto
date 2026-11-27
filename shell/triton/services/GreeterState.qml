pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

// Who can sign in, and the conversation with greetd. Only the greeter
// instance (greeter.qml) uses this.
Singleton {
    id: root

    property int selected: 0
    property bool busy: false
    property string error: ""

    readonly property var users: parse(passwd.text())
    readonly property var user: users[selected] ?? null
    readonly property bool live: marker.text() !== ""

    signal failed

    // People, as opposed to system accounts: a normal uid and a shell.
    function parse(text) {
        return text.split("\n").map(line => line.split(":")).filter(f => f.length === 7
            && Number(f[2]) >= 1000 && Number(f[2]) < 60000 && !/(nologin|false)$/.test(f[6]))
            .map(f => ({ login: f[0], name: f[4].split(",")[0] || f[0] }));
    }

    function select(index) {
        if (busy || users.length === 0)
            return;
        selected = (index + users.length) % users.length;
        error = "";
    }

    property string pending: ""

    function submit(password) {
        if (busy || !user || password === "")
            return;
        error = "";
        busy = true;
        pending = password;
        Greetd.createSession(user.login);
    }

    function fail(message) {
        pending = "";
        busy = false;
        error = message;
        failed();
    }

    function power(verb) {
        Quickshell.execDetached(["systemctl", verb]);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired)
                return;
            // One password is all we can answer with. Anything asked after
            // it (an expired password, a second factor) needs the console.
            if (root.pending === "") {
                Greetd.cancelSession();
                root.fail(message.trim() || "Could not sign in here");
                return;
            }
            const password = root.pending;
            root.pending = "";
            Greetd.respond(password);
        }
        function onAuthFailure(message) {
            root.fail("Wrong password");
        }
        function onError(error) {
            // After a wrong password greetd also rejects the cancel that
            // follows; the attempt has already been answered.
            if (!root.busy)
                return;
            Greetd.cancelSession();
            result.setText("");
            root.fail("Could not sign in");
        }
        function onReadyToLaunch() {
            // Tells greeter-session this exit was a login, not a crash.
            result.setText("ok");
            memory.setText(root.user.login);
            Greetd.launch(["/usr/local/bin/start-callisto"]);
        }
    }

    FileView {
        id: passwd
        path: "/etc/passwd"
        blockLoading: true
    }
    // Present only on the live image, whose password is public.
    FileView {
        id: marker
        path: "/run/live/medium/.disk/info"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: memory
        path: "/var/lib/callisto-greeter/last-user"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }
    FileView {
        id: result
        path: Quickshell.env("CALLISTO_GREETER_RESULT") || ""
        blockWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        const last = users.findIndex(u => u.login === memory.text().trim());
        if (last >= 0)
            selected = last;
    }
}
