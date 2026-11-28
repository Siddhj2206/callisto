"""Inside the callisto-shelltest container: load one entry point or gallery page
under a headless sway, photograph it once it has stopped changing, and print
what happened as JSON. Called by scripts/shell.py.

    shellrun.py NAME ENTRY PAGE WORKER
"""

import fcntl
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
BACKGROUND = "#111318"


def compositor(runtime: Path) -> None:
    """This worker's sway, started the first time it is needed."""
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    env = {**os.environ, "XDG_RUNTIME_DIR": str(runtime)}
    probe = ["grim", "-t", "ppm", "-"]
    ready = {**env, "WAYLAND_DISPLAY": "wayland-1"}
    if subprocess.run(probe, env=ready, capture_output=True).returncode == 0:
        return
    for stale in runtime.glob("wayland-*"):
        stale.unlink()
    config = runtime / "sway.conf"
    config.write_text(
        "output HEADLESS-1 resolution 1920x1080 position 0,0\n"
        f"output * bg {BACKGROUND} solid_color\n"
        "default_border none\n")
    env.pop("WAYLAND_DISPLAY", None)
    env.update(WLR_BACKENDS="headless", WLR_RENDERER_ALLOW_SOFTWARE="1")
    subprocess.Popen(["sway", "-c", str(config)], env=env, start_new_session=True,
                     stdout=(runtime / "sway.log").open("w"), stderr=subprocess.STDOUT)
    deadline = time.monotonic() + 30
    while subprocess.run(probe, env=ready, capture_output=True).returncode:
        if time.monotonic() > deadline:
            sys.exit("sway did not start:\n" + (runtime / "sway.log").read_text()[-2000:])
        time.sleep(0.1)


def blank(frame: bytes) -> bool:
    """Nothing but one color, judged from a spread of pixels."""
    pixels = frame.split(b"\n", 3)[3]
    return len({pixels[i:i + 3] for i in range(0, len(pixels), 3 * 997)}) <= 1


def main() -> None:
    name, entry, page, worker = sys.argv[1:]
    runtime = Path(f"/tmp/worker-{worker}")
    # One page at a time on each compositor, also between two invocations.
    lock = open(f"/tmp/worker-{worker}.lock", "w")
    fcntl.flock(lock, fcntl.LOCK_EX)
    compositor(runtime)
    env = {**os.environ, "XDG_RUNTIME_DIR": str(runtime), "WAYLAND_DISPLAY": "wayland-1",
           "QT_QPA_PLATFORM": "wayland", "CALLISTO_GALLERY": page}
    # The session runs `qs -c triton`, and the shell's IPC depends on that.
    command = ["qs", "-c", "triton"] if entry == "shell.qml" else ["qs", "-p", f"/triton/{entry}"]
    log = Path(f"/out/{name}.log")
    started = time.monotonic()
    shell = subprocess.Popen(command, env=env, stdout=log.open("w"), stderr=subprocess.STDOUT,
                             start_new_session=True)
    loaded, frame, stable, blank_frame = False, b"", False, True
    try:
        while time.monotonic() - started < 30 and shell.poll() is None:
            text = log.read_text(errors="replace")
            if "Configuration Loaded" in text:
                loaded = True
                break
            if "Failed to load" in text:
                break
            time.sleep(0.05)
        if loaded:
            # Ready is two identical, non-empty frames. A page with something
            # that never rests is photographed after a few seconds regardless.
            # A blank screen gets longer: a slow machine may not have drawn yet.
            since = time.monotonic()
            while (waited := time.monotonic() - since) < 6 or (blank_frame and waited < 20):
                time.sleep(0.25)
                new = subprocess.run(["grim", "-t", "ppm", "-"], env=env,
                                     capture_output=True, check=True).stdout
                blank_frame = blank(new)
                stable, frame = new == frame and not blank_frame, new
                if stable:
                    break
        died = shell.poll()
        if frame:
            subprocess.run(["grim", "-l", "1", f"/out/{name}.png"], env=env, check=True)
    finally:
        if shell.poll() is None:
            os.killpg(shell.pid, signal.SIGTERM)
            try:
                shell.wait(5)
            except subprocess.TimeoutExpired:
                os.killpg(shell.pid, signal.SIGKILL)
                shell.wait()
    print(json.dumps({"loaded": loaded, "died": died, "blank": bool(frame) and blank(frame),
                      "stable": stable, "seconds": round(time.monotonic() - started, 1)}))


main()
