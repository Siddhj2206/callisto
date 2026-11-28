"""What the two developer loops (shell.py and vm.py) share."""

import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / ".out"

# Container names carry the checkout, so two worktrees never share one.
CHECKOUT = hashlib.sha256(str(REPO).encode()).hexdigest()[:8]


def die(message: str):
    sys.exit(f"!! {message}")


def podman(*args: str, **kwargs) -> subprocess.CompletedProcess:
    kwargs.setdefault("check", True)
    return subprocess.run(["podman", *args], **kwargs)


def running(container: str) -> bool:
    result = podman("inspect", "-f", "{{.State.Running}}", container,
                    check=False, capture_output=True, text=True)
    return result.stdout.strip() == "true"


def device_options(path: str) -> list[str]:
    """podman options to hand a device, or /dev/dri, to a rootless container."""
    nodes = [os.path.join(path, name) for name in os.listdir(path)] if os.path.isdir(path) else [path]
    wanted = [node for node in nodes if "render" in node or node == "/dev/kvm"]
    options = ["--device", path]
    # Where it is a group that opens the device and not its mode, the container
    # has to keep the user's groups (needs crun).
    if any(os.stat(node).st_mode & 0o006 != 0o006 for node in wanted):
        options += ["--group-add", "keep-groups"]
    return options


def image(name: str, dockerfile: str, inputs: tuple[str, ...] = (), rebuild: bool = False) -> str:
    """The image for a Dockerfile, built when it or anything it copies changed."""
    digest = hashlib.sha256()
    for path in (dockerfile, *inputs):
        digest.update((REPO / path).read_bytes())
    tag = f"localhost/{name}:{digest.hexdigest()[:12]}"
    if rebuild or podman("image", "exists", tag, check=False).returncode:
        print(f"==> Building {tag}", flush=True)
        pull = ["--no-cache", "--pull=newer"] if rebuild else []
        podman("build", *pull, "-f", str(REPO / dockerfile), "-t", tag, str(REPO))
    return tag


# A container, a headless compositor or a virtual machine has no network
# manager, sound server or battery. The shell says so; that is not a defect.
EXPECTED = re.compile(
    r"Network will not work|Failed to create pipewire context|Failed to find render device"
    r"|Could not register notification server|Registration will be attempted again"
    r"|Could not attach to existing notification server|quickshell\.service\.(upower|bluetooth|networkmanager)"
    r"|org\.bluez|org\.freedesktop\.(UPower|NetworkManager)|net\.hadess\.PowerProfiles"
    r"|Could not register app ID"
)
# What QML only warns about and is a defect all the same.
BROKEN = re.compile(
    r"ERROR|ReferenceError|TypeError|SyntaxError|RangeError|is not installed|is not a type"
    r"|is not defined|Cannot assign|Unable to assign|non-existent property|Binding loop"
    r"|Failed to load|Cannot open:|QML .*: Cannot|Cannot anchor|depends on non-bindable"
    r"|WARN[^:]*: qs:@"  # a file loaded by name did not compile
)
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def log_problems(log: str) -> list[str]:
    """The lines of a Quickshell log that mean the shell is broken."""
    lines = (ANSI.sub("", line) for line in log.splitlines())
    return [line for line in lines if BROKEN.search(line) and not EXPECTED.search(line)]


def newest_change(*roots: str) -> float:
    """When anything under these last changed, deletions included."""
    newest = 0.0
    for root in roots:
        for folder, dirs, files in os.walk(REPO / root):
            # Generated: copied there by the scripts themselves.
            dirs[:] = [d for d in dirs if d not in ("fonts", "__pycache__")]
            for name in (".", *files):
                try:
                    newest = max(newest, os.stat(os.path.join(folder, name)).st_mtime)
                except FileNotFoundError:
                    pass
    return newest
