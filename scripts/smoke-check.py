#!/usr/bin/env python3
"""smoke-check.py SERIAL_SOCKET — log in on a booted live system's serial
console and check that the system and the desktop session came up."""

import re
import socket
import sys
import time

UNITS = ("callisto-shell.service", "callisto-settingsd.socket", "callisto-clipboard.service", "hypridle.service")

# Run in the guest. The end marker is split so the echoed command cannot match.
# The desktop session starts beside this login: wait for its units (they are
# judged below either way), then a moment for one that starts only to die.
CHECK = (
    "export XDG_RUNTIME_DIR=/run/user/$(id -u); "
    f"for i in $(seq 90); do [ $(systemctl --user is-active {' '.join(UNITS)} | grep -cx active) = {len(UNITS)} ] && break; sleep 1; done; "
    "sleep 5; "
    "echo SYSTEM=$(timeout 120 systemctl is-system-running --wait); "
    "systemctl --failed --no-legend --plain; systemctl --user --failed --no-legend --plain; "
    f"for u in {' '.join(UNITS)}; do echo UNIT $u $(systemctl --user is-active $u); done; "
    "echo SMOKE''DONE"
)


class Console:
    def __init__(self, path: str):
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.connect(path)
        self.socket.settimeout(1)
        self.seen = ""

    def send(self, line: str) -> None:
        self.socket.sendall((line + "\n").encode())

    def wait_for(self, text: str, seconds: int, poke: bool = False) -> str | None:
        """What came before `text`, or None. `poke` presses Enter while waiting."""
        end, poked = time.time() + seconds, time.time()
        while time.time() < end:
            if text in self.seen:
                before, self.seen = self.seen.split(text, 1)
                return before
            try:
                self.seen += self.socket.recv(4096).decode(errors="replace")
            except TimeoutError:
                pass
            if poke and time.time() - poked > 10:
                self.send("")
                poked = time.time()
        return None


def fail(why: str, detail: str = "") -> int:
    print(f"smoke: FAILED: {why}")
    if detail:
        print(detail)
    return 1


def main() -> int:
    console = Console(sys.argv[1])
    if console.wait_for("login: ", 300, poke=True) is None:
        return fail("no login prompt on the serial console")
    console.send("user")
    if console.wait_for("assword", 30) is None:
        return fail("no password prompt")
    console.send("live")
    console.send("stty -echo")
    time.sleep(1)
    console.seen = ""
    console.send(CHECK)
    output = console.wait_for("SMOKEDONE", 300)
    if output is None:
        return fail("the checks did not finish", console.seen)

    # The terminal wraps lines in escape codes.
    lines = [re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", line).strip() for line in output.splitlines()]
    report = [line for line in lines if line.startswith(("SYSTEM=", "UNIT "))]
    for line in report:
        print("smoke:", line)
    wanted = ["SYSTEM=running"] + [f"UNIT {unit} active" for unit in UNITS]
    missing = [line for line in wanted if line not in report]
    if missing:
        return fail("expected " + ", ".join(missing), output)
    print("smoke: the system and the desktop session are up")
    return 0


if __name__ == "__main__":
    sys.exit(main())
