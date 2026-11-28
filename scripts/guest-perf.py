"""Runs inside the VM, in the desktop session (`vm.py perf`): what the shell
costs. Prints one `name value unit` line per measurement."""

import json
import statistics
import subprocess
import time

UNIT = "callisto-shell.service"
SURFACES = (("launcher", "toggle"), ("quicksettings", "toggle"), ("notifications", "toggle"),
            ("clipboard", "toggle"), ("power", "toggle"), ("overview", "toggle"),
            ("wallpaper", "toggle"), ("screenshot", "open"))


def out(*argv: str) -> str:
    return subprocess.run(argv, capture_output=True, text=True).stdout


def pid() -> int:
    return int(out("systemctl", "--user", "show", "-p", "MainPID", "--value", UNIT))


def memory(process: int) -> int:
    """Proportional set size, in MiB."""
    with open(f"/proc/{process}/smaps_rollup") as rollup:
        return next(int(line.split()[1]) for line in rollup if line.startswith("Pss:")) // 1024


def ticks(process: int) -> int:
    with open(f"/proc/{process}/stat") as stat:
        fields = stat.read().rsplit(")", 1)[1].split()
    return int(fields[11]) + int(fields[12])


def mapped(process: int) -> set[str]:
    layers = json.loads(out("hyprctl", "layers", "-j") or "{}")
    return {layer["namespace"] for monitor in layers.values()
            for level in monitor["levels"].values() for layer in level
            if layer["pid"] == process}


def start() -> int:
    """Restart the shell: milliseconds until the desktop and the bar are up."""
    subprocess.run(["systemctl", "--user", "reset-failed", UNIT], capture_output=True)
    began = time.monotonic()
    subprocess.run(["systemctl", "--user", "restart", UNIT], check=True)
    while time.monotonic() - began < 30:
        names = mapped(pid())
        if "triton-desktop" in names and len(names) > 1:
            return round((time.monotonic() - began) * 1000)
        time.sleep(0.01)
    raise SystemExit("the shell did not come up")


def report(name: str, value: int, unit: str) -> None:
    print(f"{name:<22} {value:>6} {unit}", flush=True)


report("startup (median of 5)", statistics.median([start() for _ in range(5)]), "ms")
time.sleep(15)
shell = pid()
report("memory at rest", memory(shell), "MiB")
before = ticks(shell)
time.sleep(30)
report("cpu at rest, 30 s", (ticks(shell) - before) * 10, "ms")

for target, function in SURFACES:
    for _ in range(2):  # open, then close
        subprocess.run(["qs", "-c", "triton", "ipc", "call", target, function], capture_output=True)
        time.sleep(1.5)
time.sleep(10)
report("memory after surfaces", memory(shell), "MiB")
before = ticks(shell)
time.sleep(30)
report("cpu after surfaces", (ticks(shell) - before) * 10, "ms")
