pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pam
import QtQuick

// Session lock state: owns the lock lifecycle and PAM authentication.
// The compositor-facing half (WlSessionLock) lives in lock/LockWindow.qml;
// this singleton is the brain both the keybind IPC and the lock surface
// talk to.
//
// Auth flow: submit(pw) starts a PamContext against the "login" config.
// PAM asks for the password (responseRequired), we answer it, completed()
// decides. Wrong passwords re-arm the prompt; success unlocks the session.

Singleton {
    id: root

    property bool locked: false
    // Mirror of the lockscreen's field states: 0 idle, 1 typing, 2 wrong, 3 unlocking
    property int fieldState: 1
    property string errorText: ""

    function lock() {
        if (!root.locked) {
            root.fieldState = 1;
            root.errorText = "";
            root.locked = true;
        }
    }

    function unlock() {
        root.locked = false;
    }

    function submit(pw) {
        if (pam.active)
            return;
        root.fieldState = 3; // unlocking
        pendingPassword = pw;
        pam.start();
    }

    property string pendingPassword: ""

    PamContext {
        id: pam
        config: "login"

        onResponseRequiredChanged: {
            if (responseRequired && root.pendingPassword !== "") {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.errorText = "";
                root.unlock();
            } else {
                root.fieldState = 2; // wrong
                root.errorText = pam.messageIsError ? pam.message : "Incorrect password";
            }
        }

        onError: error => {
            root.fieldState = 2;
            root.errorText = "Authentication error";
        }
    }
}
