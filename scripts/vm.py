#!/usr/bin/env python3
"""The virtual machine: boot the ISO, put your changes on it, look, type.

    vm.py up                 boot the ISO headless with 3D, wait for the desktop,
                             then push the working tree
    vm.py push [--watch]     put the working tree on the running machine
    vm.py shot [name]        screenshot to .out/vm/<name>.png
    vm.py run CMD...         run in the desktop session, as the live user
    vm.py root CMD...        run as root
    vm.py key meta_l-ret     press keys (QEMU key names, joined with -)
    vm.py type 'text'        type on a US keyboard
    vm.py click X Y          click at screenshot coordinates
    vm.py log                the shell's journal
    vm.py gpu                what renders the guest's graphics
    vm.py perf               what the shell costs: startup, memory, idle cpu
    vm.py status | down
    vm.py smoke              boot the ISO as shipped and check it (CI)

The ISO is callisto-amd64.hybrid.iso here, or ISO=path, or --iso.

QEMU runs in a container (containers/vm.Dockerfile). `up` hands the booting
system a small agent as a systemd credential, so nothing for development is on
the image. State, logs and screenshots are in .out/vm/.
"""

import argparse
import base64
import io
import json
import os
import re
import shlex
import socket
import struct
import subprocess
import sys
import tarfile
import time
import zlib
from contextlib import contextmanager
from pathlib import Path

import devlib
from devlib import REPO, die, podman

CONTAINER = f"callisto-vm-{devlib.CHECKOUT}"
STATE = devlib.OUT / "vm"
RENDER_NODE = "/dev/dri/renderD128"
SOURCES = ("bin", "configs", "design", "shell", "licenses")
SIZE = (1920, 1080)


def vm_image(rebuild: bool = False) -> str:
    return devlib.image("callisto-vm", "containers/vm.Dockerfile", rebuild=rebuild)


def state() -> dict:
    try:
        return json.loads((STATE / "state.json").read_text())
    except (OSError, ValueError):
        return {}


def need_running() -> None:
    if not devlib.running(CONTAINER):
        die("no machine is running: make vm")


# --- Sockets -----------------------------------------------------------------

@contextmanager
def connect(name: str):
    """A connection to one of the machine's sockets in STATE."""
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    # A socket path is limited to 107 bytes; a worktree's can be longer.
    here = os.getcwd()
    os.chdir(STATE)
    try:
        client.connect(name)
    except OSError as error:
        die(f"cannot reach the machine ({name}: {error})")
    finally:
        os.chdir(here)
    try:
        yield client
    finally:
        client.close()


class Qmp:
    def __init__(self, client: socket.socket):
        self.file = client.makefile("rwb")
        client.settimeout(30)
        self.file.readline()  # greeting
        self("qmp_capabilities")

    def __call__(self, command: str, **arguments):
        message = {"execute": command, "arguments": arguments}
        self.file.write(json.dumps(message).encode() + b"\n")
        self.file.flush()
        while True:
            reply = json.loads(self.file.readline())
            if "error" in reply:
                die(f"{command}: {reply['error']['desc']}")
            if "return" in reply:
                return reply["return"]


@contextmanager
def qmp():
    need_running()
    with connect("qmp.sock") as client:
        yield Qmp(client)


def agent(argv: list[str], stdin: bytes = b"", timeout: int = 60, wait: float | None = None):
    """Run argv in the guest as root: (exit status, stdout, stderr), or None if
    the agent did not answer within `wait` seconds."""
    ident = os.urandom(8).hex()
    request = {"id": ident, "argv": argv, "timeout": timeout,
               "stdin": base64.b64encode(stdin).decode()}
    deadline = time.monotonic() + (wait or timeout + 15)
    with connect("agent.sock") as client:
        client.settimeout(max(0.1, deadline - time.monotonic()))
        received = b""
        try:
            # The newline first closes anything an earlier caller left half-sent.
            client.sendall(b"\n" + json.dumps(request).encode() + b"\n")
            while time.monotonic() < deadline:
                client.settimeout(max(0.1, deadline - time.monotonic()))
                chunk = client.recv(1 << 16)
                if not chunk:
                    break
                received += chunk
                while b"\n" in received:
                    line, received = received.split(b"\n", 1)
                    try:
                        reply = json.loads(line)
                    except ValueError:
                        continue
                    if reply.get("id") == ident:
                        return (reply["rc"], base64.b64decode(reply["out"]),
                                base64.b64decode(reply["err"]))
        except TimeoutError:
            pass
    return None


def root(script: str, *args: str, **kwargs) -> tuple[int, str]:
    """A shell script as root in the guest: (status, combined output)."""
    reply = agent(["sh", "-c", script, "sh", *args], **kwargs)
    if reply is None:
        die("the guest did not answer (vm.py status)")
    return reply[0], (reply[1] + reply[2]).decode(errors="replace")


# Runs "$@" as the live user with what the desktop session exports.
SESSION = r"""
export XDG_RUNTIME_DIR=/run/user/$(id -u)
eval "$(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_CURRENT_DESKTOP|PATH)=' | sed 's/^/export /')"
cd "$HOME"
exec "$@"
"""


def session_argv(argv: list[str]) -> list[str]:
    return ["runuser", "-u", "user", "--", "sh", "-c", SESSION, "sh", *argv]


def session(argv: list[str], **kwargs) -> tuple[int, bytes, bytes]:
    reply = agent(session_argv(argv), **kwargs)
    if reply is None:
        die("the guest did not answer (vm.py status)")
    return reply


# --- Up and down -------------------------------------------------------------

def boot_files(iso: Path, image: str) -> tuple[Path, str]:
    """The ISO's kernel and initrd, and its default command line."""
    boot = STATE / "boot"
    stamp = f"{iso} {iso.stat().st_size} {iso.stat().st_mtime_ns}"
    if not (boot / "stamp").exists() or (boot / "stamp").read_text() != stamp:
        boot.mkdir(parents=True, exist_ok=True)
        for old in boot.iterdir():
            old.chmod(0o644)
            old.unlink()
        script = """
            set -e
            get() { xorriso -osirrox on -indev /iso.iso -extract "$1" "$2" 2>/dev/null; }
            get /boot/grub/grub.cfg /boot/grub.cfg
            get "$(awk '$1 == "linux" { print $2; exit }' /boot/grub.cfg)" /boot/vmlinuz
            get "$(awk '$1 == "initrd" { print $2; exit }' /boot/grub.cfg)" /boot/initrd
        """
        podman("run", "--rm", "--security-opt", "label=disable", "-v", f"{iso}:/iso.iso:ro",
               "-v", f"{boot}:/boot", image, "sh", "-c", script)
        (boot / "stamp").write_text(stamp)
    grub = (boot / "grub.cfg").read_text()
    line = re.search(r"^\s*linux\s+\S+\s+(.*)$", grub, re.MULTILINE)
    if not line:
        die(f"no kernel line in {iso}'s boot menu")
    return boot, line.group(1).replace("findiso=${iso_path}", "").strip()


def agent_credentials() -> list[str]:
    """QEMU options that make the guest's systemd create and start the agent."""
    code = base64.b64encode((REPO / "scripts/vm-agent.py").read_bytes()).decode()
    unit = (
        "[Unit]\nDescription=Development agent (vm.py)\n"
        "[Service]\n"
        f"ExecStart=/usr/bin/python3 -c \"import base64;exec(base64.b64decode('{code}'))\"\n"
        "Restart=always\n"
    )
    credentials = {
        "systemd.extra-unit.callisto-dev.service": unit,
        "systemd.unit-dropin.multi-user.target": "[Unit]\nWants=callisto-dev.service\n",
    }
    options = []
    for name, value in credentials.items():
        encoded = base64.b64encode(value.encode()).decode()
        options += ["-smbios", f"type=11,value=io.systemd.credential.binary:{name}={encoded}"]
    return options


def up(args) -> None:
    if devlib.running(CONTAINER):
        if not args.fresh:
            print("Already running (vm.py up --fresh starts over).")
            if not args.no_push and not args.as_shipped:
                push(args)
            return
        down(args)
    iso = Path(args.iso or os.environ.get("ISO") or REPO / "callisto-amd64.hybrid.iso").resolve()
    if not iso.is_file():
        die(f"{iso} not found: run 'make iso', or set ISO=path")
    if not os.access("/dev/kvm", os.R_OK | os.W_OK):
        die("/dev/kvm is not usable")
    gpu = args.gpu
    if gpu == "auto":
        gpu = "gl" if os.access(RENDER_NODE, os.R_OK | os.W_OK) else "sw"

    STATE.mkdir(parents=True, exist_ok=True)
    for name in ("qmp.sock", "agent.sock", "serial.sock", "vnc.sock", "serial.log", "qemu.log"):
        (STATE / name).unlink(missing_ok=True)
    image = vm_image()
    started = time.monotonic()

    run = ["run", "--detach", "--rm", "--name", CONTAINER, "--security-opt", "label=disable",
           *devlib.device_options("/dev/kvm"), "--stop-timeout", "5",
           "-v", f"{STATE}:/vm", "-v", f"{iso}:/iso.iso:ro"]
    memory = args.memory
    qemu = [
        "qemu-system-x86_64", "-enable-kvm", "-cpu", "host",
        "-smp", str(min(4, os.cpu_count() or 4)), "-m", memory,
        "-machine", "q35,memory-backend=mem",
        "-object", f"memory-backend-memfd,id=mem,size={memory},share=on",
        "-cdrom", "/iso.iso",
        "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
        "-device", "virtio-rng-pci", "-device", "virtio-tablet-pci",
        "-chardev", "socket,id=serial,path=/vm/serial.sock,server=on,wait=off,logfile=/vm/serial.log",
        "-serial", "chardev:serial",
        "-qmp", "unix:/vm/qmp.sock,server=on,wait=off",
    ]

    size = f"xres={SIZE[0]},yres={SIZE[1]}"
    if gpu == "gl":
        run += devlib.device_options("/dev/dri")
        device = f"virtio-vga-gl,{size}"
        display = "gtk,gl=on" if args.window else f"egl-headless,rendernode={RENDER_NODE}"
    else:
        device = f"virtio-vga,{size}"
        display = "gtk" if args.window else "none"
    qemu += ["-device", device, "-display", display]
    if not args.window:
        qemu += ["-vnc", "unix:/vm/vnc.sock"]  # how screen() reads the screen

    if args.window:
        runtime, wayland = os.environ.get("XDG_RUNTIME_DIR"), os.environ.get("WAYLAND_DISPLAY")
        if not runtime or not wayland:
            die("--window needs a Wayland session")
        run += ["-v", f"{Path(runtime) / wayland}:/wl/wayland-0",
                "-e", "XDG_RUNTIME_DIR=/wl", "-e", "WAYLAND_DISPLAY=wayland-0",
                "-e", "GDK_BACKEND=wayland"]

    if not args.as_shipped:
        boot, cmdline = boot_files(iso, image)
        run += ["-v", f"{boot}:/kernel:ro"]
        qemu += ["-kernel", "/kernel/vmlinuz", "-initrd", "/kernel/initrd", "-append", cmdline,
                 "-device", "virtio-serial-pci",
                 "-chardev", "socket,id=agent,path=/vm/agent.sock,server=on,wait=off",
                 "-device", "virtserialport,chardev=agent,name=org.callisto.dev",
                 *agent_credentials()]
    else:
        qemu += ["-boot", "d"]

    podman(*run, image, "sh", "-c", 'exec "$@" 2>/vm/qemu.log', "sh", *qemu,
           stdout=subprocess.DEVNULL)
    (STATE / "state.json").write_text(json.dumps(
        {"gpu": gpu, "iso": str(iso), "as_shipped": args.as_shipped}))

    sockets = ["qmp.sock", "serial.sock"] + ([] if args.as_shipped else ["agent.sock"])
    wait_until(lambda: all((STATE / name).exists() for name in sockets), 20, "QEMU to start")
    print(f"==> Booting {iso.name} ({'3D on ' + RENDER_NODE if gpu == 'gl' else 'software rendering'})",
          flush=True)
    if args.as_shipped:
        return

    wait_until(lambda: agent(["true"], wait=1) is not None, args.timeout, "the guest to boot")
    print(f"    system up      {time.monotonic() - started:5.1f}s", flush=True)
    wait_until(shell_loaded, args.timeout, "the desktop session")
    print(f"    desktop ready  {time.monotonic() - started:5.1f}s", flush=True)
    # A machine left alone while someone reads a screenshot must not lock itself.
    session(["systemctl", "--user", "stop", "hypridle.service"])
    wait_drawn()
    if not args.no_push:
        push(args)


def shell_loaded() -> bool:
    status, _ = root(
        'journalctl -o cat -b _SYSTEMD_USER_UNIT=callisto-shell.service | grep -q "Configuration Loaded"')
    return status == 0


# "Configuration Loaded" comes before the first frame, and the wallpaper later
# still. Drawn is two captures in a row that all but match (a toast's progress bar
# never rests) and are not nearly all one color.
SETTLED = r"""
import subprocess, time
last, end = [], time.monotonic() + 30
while time.monotonic() < end:
    frame = subprocess.run(["grim", "-t", "ppm", "-"], capture_output=True).stdout
    pixels = frame.split(b"\n", 3)[-1]
    sample = [pixels[i:i + 3] for i in range(0, len(pixels), 3 * 997)]
    changed = sum(a != b for a, b in zip(sample, last))
    if len(last) == len(sample) and changed <= len(sample) // 200 and len(set(sample)) > 8:
        raise SystemExit(0)
    last = sample
    time.sleep(0.2)
raise SystemExit(1)
"""


def wait_drawn() -> None:
    if session(["python3", "-c", SETTLED], timeout=45)[0]:
        print("    (the screen has not settled; a screenshot may be early)")


def wait_until(condition, seconds: float, what: str) -> None:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if not devlib.running(CONTAINER):
            log = STATE / "qemu.log"
            die(f"QEMU stopped while waiting for {what}:\n{log.read_text() if log.exists() else ''}")
        if condition():
            return
        time.sleep(0.3)
    die(f"timed out waiting for {what}; the machine is still up, see {STATE / 'serial.log'}")


def down(_args) -> None:
    podman("rm", "--force", "--ignore", "--time", "5", CONTAINER, stdout=subprocess.DEVNULL)


def status(_args) -> None:
    if not devlib.running(CONTAINER):
        print("down")
        sys.exit(1)
    info = state()
    answers = not info.get("as_shipped") and agent(["true"], wait=3) is not None
    print(f"up: {info.get('iso')}, {info.get('gpu')}, agent {'answers' if answers else 'silent'}")


# --- Push --------------------------------------------------------------------

def staged() -> bytes:
    """What the image would hold from this tree, as a tar."""
    stage = STATE / "stage"
    subprocess.run([str(REPO / "scripts/sync-configs.sh")], check=True, stdout=subprocess.DEVNULL,
                   env={**os.environ, "STAGE_DIR": str(stage)})
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz", compresslevel=1) as tar:
        tar.add(stage, arcname=".")
    return buffer.getvalue()


def touched(names: list[str], *prefixes: str) -> bool:
    return any(name.startswith(prefixes) for name in names)


def push(args) -> bool:
    need_running()
    if state().get("as_shipped"):
        die("this machine was booted as shipped and has no agent: vm.py up --fresh")
    started = time.monotonic()
    apply = (REPO / "scripts/vm-apply.py").read_text()
    reply = agent(["python3", "-c", apply], stdin=staged())
    if reply is None or reply[0]:
        die("push failed:\n" + (reply[2].decode() if reply else "no answer"))
    result = json.loads(reply[1])
    names = result["changed"] + result["removed"]
    if not names:
        print(f"push: nothing to change ({time.monotonic() - started:.1f}s)")
        return True
    for name in names[:12]:
        print(f"    {'-' if name in result['removed'] else '+'} /{name}")
    if len(names) > 12:
        print(f"    ... and {len(names) - 12} more")

    ok, actions = True, []
    since = root("date +'%Y-%m-%d %H:%M:%S'")[1].strip()

    def user(*argv: str, what: str) -> None:
        nonlocal ok
        rc, out, err = session(list(argv))
        actions.append(what)
        if rc:
            ok = False
            print(f"!! not {what}: {(out + err).decode(errors='replace').strip()}")

    if touched(names, "usr/lib/systemd/user/"):
        user("systemctl", "--user", "daemon-reload", what="reloaded units")
    if touched(names, "usr/share/fonts/"):
        user("fc-cache", "-f", what="rebuilt the font cache")
    if touched(names, "usr/local/bin/callisto-settingsd", "usr/local/bin/callisto-apply",
               "usr/lib/systemd/user/callisto-settingsd"):
        user("systemctl", "--user", "restart", "callisto-settingsd.service",
             what="restarted the settings daemon")
    if touched(names, "usr/local/bin/callisto-apply", "usr/share/callisto/"):
        user("callisto-apply", what="applied settings")
    if touched(names, "usr/share/callisto/hypr/", "usr/share/callisto/keybindings.json",
               "etc/skel/.config/hypr/"):
        user("hyprctl", "reload", what="reloaded Hyprland")
        errors = session(["hyprctl", "configerrors"])[1].decode().strip()
        if errors and errors != "no errors":
            ok = False
            print(f"!! Hyprland config errors:\n{errors}")
    if touched(names, "etc/xdg/quickshell/", "usr/share/fonts/", "usr/share/callisto/tokens.json",
               "usr/lib/systemd/user/callisto-shell"):
        # Several broken pushes in a row would otherwise hit the start limit.
        session(["systemctl", "--user", "reset-failed", "callisto-shell.service"])
        user("systemctl", "--user", "restart", "callisto-shell.service", what="restarted the shell")
        deadline = time.monotonic() + 30
        while True:
            journal = shell_log(since)
            loaded = "Configuration Loaded" in journal
            if loaded or "Failed to load" in journal or time.monotonic() > deadline:
                break
            time.sleep(0.2)
        problems = list(dict.fromkeys(devlib.log_problems(journal)))
        if not loaded or problems:
            ok = False
            print("!! the shell did not load cleanly:")
            print("\n".join(problems) or journal)
        if loaded:
            wait_drawn()

    done = ", ".join(actions) or "nothing needed restarting"
    print(f"push: {len(names)} files, {done} ({time.monotonic() - started:.1f}s)")
    return ok


def watch(args) -> None:
    push(args)
    print("==> Watching; Ctrl+C stops.", flush=True)
    seen = devlib.newest_change(*SOURCES)
    try:
        while True:
            time.sleep(0.3)
            now = devlib.newest_change(*SOURCES)
            if now != seen:
                time.sleep(0.2)  # let an editor finish writing
                seen = devlib.newest_change(*SOURCES)
                push(args)
                sys.stdout.flush()
    except KeyboardInterrupt:
        pass


def push_command(args) -> None:
    if args.watch:
        watch(args)
    elif not push(args):
        sys.exit(1)


# --- Looking and typing ------------------------------------------------------

def png(width: int, height: int, rgb: bytes) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    stride = width * 3
    rows = b"".join(b"\0" + rgb[y * stride:(y + 1) * stride] for y in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(rows, 1)) + chunk(b"IEND", b""))


def screen(path: Path) -> None:
    """The emulated screen, read over VNC. QMP's screendump has nothing to give
    once the guest scans out a GL texture."""
    need_running()
    if not (STATE / "vnc.sock").exists():
        die("a machine shown in a window has only its window: vm.py shot, without --screen")
    with connect("vnc.sock") as client:
        client.settimeout(20)
        stream = client.makefile("rb")

        def read(count: int) -> bytes:
            data = stream.read(count)
            if len(data) != count:
                die("the VNC server hung up")
            return data

        read(12)
        client.sendall(b"RFB 003.008\n")
        read(read(1)[0])  # security types
        client.sendall(b"\x01")  # none
        read(4)
        client.sendall(b"\x01")  # shared
        width, height = struct.unpack(">HH", read(4))
        read(16)
        read(struct.unpack(">I", read(4))[0])  # name
        # 32 bits a pixel, bytes in the order R G B x; raw rectangles only.
        client.sendall(struct.pack(">B3xBBBBHHHBBB3x", 0, 32, 24, 0, 1, 255, 255, 255, 0, 8, 16))
        client.sendall(struct.pack(">BxHi", 2, 1, 0))
        client.sendall(struct.pack(">BBHHHH", 3, 0, 0, 0, width, height))
        frame, missing = bytearray(width * height * 3), width * height
        while missing > 0:
            kind = read(1)[0]
            if kind == 2:  # bell
                continue
            if kind == 3:  # clipboard
                read(struct.unpack(">3xI", read(7))[0])
                continue
            for _ in range(struct.unpack(">xH", read(3))[0]):
                x, y, w, h, encoding = struct.unpack(">HHHHi", read(12))
                if encoding != 0:
                    die(f"unexpected VNC encoding {encoding}")
                pixels = read(w * h * 4)
                rgb = bytearray(w * h * 3)
                for channel in range(3):
                    rgb[channel::3] = pixels[channel::4]
                for row in range(h):
                    start = ((y + row) * width + x) * 3
                    frame[start:start + w * 3] = rgb[row * w * 3:(row + 1) * w * 3]
                missing -= w * h
    path.write_bytes(png(width, height, bytes(frame)))


def shot(args) -> None:
    need_running()
    path = STATE / f"{args.name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    # grim sees what the compositor drew; the emulated screen also covers what
    # comes before a session (boot, the greeter, a hung desktop).
    if not args.screen and not state().get("as_shipped"):
        reply = agent(session_argv(["grim", "-c", "-l", "1", "-"]), timeout=20)
        if reply and reply[0] == 0:
            path.write_bytes(reply[1])
            print(path)
            return
        print("(no desktop session to ask; taking the emulated screen)", file=sys.stderr)
    screen(path)
    print(path)


KEYS = {
    " ": "spc", ".": "dot", ",": "comma", "/": "slash", "\\": "backslash", "-": "minus",
    "=": "equal", ";": "semicolon", "'": "apostrophe", "`": "grave_accent", "[": "bracket_left",
    "]": "bracket_right", "\n": "ret", "\t": "tab",
}
SHIFTED = dict(zip('!@#$%^&*()_+:"~{}|<>?', "1234567890-=;'`[]\\,./"))
ALIASES = {"enter": "ret", "return": "ret", "super": "meta_l", "meta": "meta_l", "win": "meta_l",
           "space": "spc", "escape": "esc", "control": "ctrl"}


def press(monitor: Qmp, names: list[str]) -> None:
    keys = [{"type": "qcode", "data": ALIASES.get(name, name)} for name in names]
    monitor("send-key", keys=keys, **{"hold-time": 20})
    time.sleep(0.04)


def key(args) -> None:
    with qmp() as monitor:
        for combo in args.combo:
            press(monitor, combo.split("-"))


def type_text(args) -> None:
    with qmp() as monitor:
        for char in args.text:
            names = []
            if char.isupper() or char in SHIFTED:
                names.append("shift")
                char = SHIFTED.get(char, char.lower())
            if not (char.isascii() and (char.isalnum() or char in KEYS)):
                die(f"cannot type {char!r}")
            press(monitor, [*names, KEYS.get(char, char)])


def click(args) -> None:
    def at(axis: str, value: int, size: int) -> dict:
        return {"type": "abs", "data": {"axis": axis, "value": value * 32767 // (size - 1)}}

    with qmp() as monitor:
        monitor("input-send-event", events=[at("x", args.x, SIZE[0]), at("y", args.y, SIZE[1])])
        if args.command == "move":
            return
        for down_ in (True, False):
            time.sleep(0.05)
            monitor("input-send-event",
                    events=[{"type": "btn", "data": {"button": args.button, "down": down_}}])


def drag(args) -> None:
    """Press at one place and move to another, a step at a time. With --shot,
    a screenshot is taken before letting go: what a drag shows meanwhile."""
    def at(x: int, y: int) -> list:
        return [{"type": "abs", "data": {"axis": axis, "value": value * 32767 // (size - 1)}}
                for axis, value, size in (("x", x, SIZE[0]), ("y", y, SIZE[1]))]

    def button(down_: bool) -> dict:
        return {"type": "btn", "data": {"button": "left", "down": down_}}

    with qmp() as monitor:
        monitor("input-send-event", events=at(args.x, args.y))
        time.sleep(0.1)
        monitor("input-send-event", events=[button(True)])
        for step in range(1, args.steps + 1):
            time.sleep(0.03)
            monitor("input-send-event", events=at(args.x + (args.to_x - args.x) * step // args.steps,
                                                  args.y + (args.to_y - args.y) * step // args.steps))
        if args.shot:
            time.sleep(0.7)
            shot(argparse.Namespace(name=args.shot, screen=False))
        monitor("input-send-event", events=[button(False)])


def run_command(args) -> None:
    need_running()
    argv = args.argv[1:] if args.argv[:1] == ["--"] else args.argv
    if not argv:
        die("run what?")
    # One argument is a shell line, several are a command.
    if len(argv) == 1:
        argv = ["sh", "-c", argv[0]]
    if args.command == "run":
        argv = session_argv(argv)
    reply = agent(argv, timeout=args.timeout)
    if reply is None:
        die("the guest did not answer")
    sys.stdout.buffer.write(reply[1])
    sys.stderr.buffer.write(reply[2])
    sys.exit(reply[0])


def shell_log(since: str = "") -> str:
    return root('journalctl -o cat _SYSTEMD_USER_UNIT=callisto-shell.service -b '
                '${1:+--since "$1"}', since)[1]


def log(_args) -> None:
    need_running()
    print(shell_log(), end="")


def gpu(_args) -> None:
    need_running()
    out = session(["sh", "-c", """
        eglinfo -B -p wayland 2>/dev/null | grep -E 'OpenGL ES profile (renderer|version)|OpenGL core profile renderer'
        grep -hE 'Renderer:|GL_RENDERER|Using: OpenGL' "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" \
            "$HOME/.local/state/callisto/hyprland.log" 2>/dev/null | sort -u
    """], timeout=60)[1].decode()
    print(out.strip())
    renderers = [line for line in out.splitlines() if re.search(r"profile renderer|\bRenderer: ", line)]
    if renderers and all("virgl" in line.lower() for line in renderers):
        print("==> accelerated (virgl)")
    else:
        print("==> NOT accelerated")
        sys.exit(1)


def perf(_args) -> None:
    need_running()
    script = (REPO / "scripts/guest-perf.py").read_bytes()
    status, output, errors = session(["python3", "-"], stdin=script, timeout=240)
    sys.stdout.write(output.decode())
    sys.stderr.write(errors.decode(errors="replace"))
    sys.exit(status)


# --- Smoke test --------------------------------------------------------------

def smoke(args) -> None:
    """Boot as shipped, through the ISO's own boot loader, with no agent."""
    args.fresh, args.as_shipped, args.window, args.no_push = True, True, False, True
    up(args)
    try:
        command = [sys.executable, str(REPO / "scripts/smoke-check.py"), "serial.sock"]
        passed = subprocess.run(command, cwd=STATE).returncode == 0
        screen(STATE / "desktop.png")
        print(f"==> Screenshot {STATE / 'desktop.png'}, serial console {STATE / 'serial.log'}")
    finally:
        if not args.keep:
            down(args)
    sys.exit(0 if passed else 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True, metavar="command")

    def command(name: str, function):
        sub = commands.add_parser(name)
        sub.set_defaults(function=function)
        return sub

    for name, function, default_gpu in (("up", up, "auto"), ("smoke", smoke, "sw")):
        sub = command(name, function)
        sub.add_argument("--iso")
        sub.add_argument("--gpu", choices=("auto", "gl", "sw"), default=default_gpu)
        sub.add_argument("--memory", default="4G")
        sub.add_argument("--timeout", type=int, default=300)
    up_parser = commands.choices["up"]
    up_parser.add_argument("--fresh", action="store_true", help="restart a running machine")
    up_parser.add_argument("--window", action="store_true", help="show it on your desktop")
    up_parser.add_argument("--no-push", action="store_true", help="leave the ISO as it is")
    up_parser.add_argument("--as-shipped", action="store_true",
                           help="boot through the ISO's boot menu, without the agent")
    commands.choices["smoke"].add_argument("--keep", action="store_true", help="leave it running")

    command("down", down)
    command("status", status)
    command("push", push_command).add_argument("--watch", action="store_true")
    sub = command("shot", shot)
    sub.add_argument("name", nargs="?", default="shot")
    sub.add_argument("--screen", action="store_true", help="the emulated screen, not grim")
    command("key", key).add_argument("combo", nargs="+")
    command("type", type_text).add_argument("text")
    for name in ("click", "move"):
        sub = command(name, click)
        sub.add_argument("x", type=int)
        sub.add_argument("y", type=int)
        sub.add_argument("--button", choices=("left", "middle", "right"), default="left")
    sub = command("drag", drag)
    for name in ("x", "y", "to_x", "to_y"):
        sub.add_argument(name, type=int)
    sub.add_argument("--steps", type=int, default=12)
    sub.add_argument("--shot", metavar="NAME", help="screenshot while still held")
    for name in ("run", "root"):
        sub = command(name, run_command)
        sub.add_argument("--timeout", type=int, default=60)
        sub.add_argument("argv", nargs=argparse.REMAINDER)
    command("log", log)
    command("gpu", gpu)
    command("perf", perf)

    args = parser.parse_args()
    args.function(args)


if __name__ == "__main__":
    main()
