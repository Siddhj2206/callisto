pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

// The lock and its authentication. The window half is surfaces/lock/LockHost.
//
// Whether the session is locked is also written under XDG_RUNTIME_DIR, so a
// shell that crashes or restarts while locked locks again (Hyprland allows the
// takeover). The directory does not survive a reboot.
Singleton {
    id: root

    property bool locked: false
    property bool busy: false // checking a password
    property string error: ""
    property real lockedAt: 0

    signal failed

    function lock() {
        if (locked)
            return;
        error = "";
        busy = false;
        lockedAt = Date.now();
        locked = true;
        marker.setText("locked");
    }

    // Only a successful authentication gets here; there is no IPC for it.
    function release() {
        locked = false;
        busy = false;
        marker.setText("");
    }

    function submit(password) {
        if (!locked || pam.active || password === "")
            return;
        error = "";
        busy = true;
        pending = password;
        if (!pam.start())
            fail("Could not check the password");
    }

    property string pending: ""

    function fail(message) {
        pending = "";
        busy = false;
        error = message;
        failed();
    }

    // Our own stack, or "login" where it is not installed: a missing file
    // must never leave no way back in.
    FileView {
        id: stack
        path: "/etc/pam.d/callisto-lock"
        blockLoading: true
        printErrors: false
    }

    PamContext {
        id: pam
        config: stack.text() !== "" ? "callisto-lock" : "login"

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.pending);
            root.pending = "";
        }
        onCompleted: result => {
            if (result === PamResult.Success)
                root.release();
            else
                root.fail("Wrong password");
        }
        onError: error => root.fail("Could not check the password")
    }

    FileView {
        id: marker
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/callisto-locked"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        if (marker.text().trim() === "locked")
            lock();
    }
}
