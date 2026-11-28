"""The development agent, run as root inside a `vm.py up` machine.

It is not part of the image: vm.py hands it to the booting system as a systemd
credential (an SMBIOS string), and it answers on a virtio serial port. One JSON
request per line, one JSON answer per line.
"""

import base64
import json
import os
import subprocess
import time

PORT = "/dev/virtio-ports/org.callisto.dev"


def answer(request: dict) -> dict:
    stdin = base64.b64decode(request.get("stdin", ""))
    try:
        done = subprocess.run(request["argv"], input=stdin, capture_output=True,
                              timeout=request.get("timeout", 60))
        rc, out, err = done.returncode, done.stdout, done.stderr
    except subprocess.TimeoutExpired:
        rc, out, err = 124, b"", b"timed out\n"
    except OSError as error:
        rc, out, err = 127, b"", f"{error}\n".encode()
    return {"id": request["id"], "rc": rc,
            "out": base64.b64encode(out).decode(), "err": base64.b64encode(err).decode()}


def main() -> None:
    while not os.path.exists(PORT):
        time.sleep(0.2)
    port = os.open(PORT, os.O_RDWR)
    pending = b""
    while True:
        chunk = os.read(port, 1 << 16)
        if not chunk:  # nobody is connected on the host side
            time.sleep(0.05)
            continue
        pending += chunk
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            try:
                reply = json.dumps(answer(json.loads(line))).encode() + b"\n"
            except (ValueError, KeyError):
                continue  # what is left of a request somebody gave up on
            while reply:
                try:
                    reply = reply[os.write(port, reply):]
                except OSError:
                    break


main()
