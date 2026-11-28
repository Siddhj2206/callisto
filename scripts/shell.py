#!/usr/bin/env python3
"""The shell without a VM: load it in a container under a headless sway.

    shell.py                    every entry point and gallery page
    shell.py power lock shell   just these
    shell.py --watch power      again on every save
    shell.py --window [name]    live, as a window on your desktop
    shell.py --list | --down

Screenshots and logs go to .out/shell/<name>.png and .log. A name fails if it
does not load, comes out blank, exits, or logs an error. The container is kept
running for the next time.

This is sway, not Hyprland: blur, workspaces, keybinds and anything else of
Hyprland's is seen in the VM (make vm).
"""

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from queue import Queue

import devlib
from devlib import REPO, die, podman

CONTAINER = f"callisto-shell-{devlib.CHECKOUT}"
OUT = devlib.OUT / "shell"
ENTRIES = ("shell", "greeter", "settings-app")
# What the image copies in, so that a change to any of it rebuilds the image.
INPUTS = ("configs/matugen.env", "bin/callisto-apply", "design/tokens.json",
          "configs/callisto/default-settings.json", "design/wallpaper.jpg",
          "configs/hypr/keybindings.json")


def pages() -> list[str]:
    return sorted(path.stem for path in (REPO / "shell/triton/gallery").glob("*.qml"))


def target(name: str) -> tuple[str, str, str]:
    """name -> (name, entry file, gallery page). A bare name is the entry point
    if there is one, else the page; gallery-<name> is always the page."""
    name = name.removesuffix(".qml")
    if name in ENTRIES:
        return name, f"{name}.qml", ""
    page = name.removeprefix("gallery-")
    if page in pages():
        return f"gallery-{page}", "gallery.qml", page
    die(f"no such entry point or gallery page: {name} (see --list)")


def everything() -> list[str]:
    return [*ENTRIES, *(f"gallery-{page}" for page in pages())]


def image(rebuild: bool = False) -> str:
    return devlib.image("callisto-shelltest", "containers/shelltest.Dockerfile", INPUTS, rebuild)


def run_options() -> list[str]:
    # The shell loads its fonts from its own tree.
    fonts = REPO / "shell/triton/fonts"
    fonts.mkdir(exist_ok=True)
    for font in (REPO / "design/fonts").glob("*.ttf"):
        copy = fonts / font.name
        if not copy.exists() or copy.stat().st_mtime < font.stat().st_mtime:
            copy.write_bytes(font.read_bytes())
    options = [
        # The host user is the image's, whatever its number here (CI: 1001).
        "--userns=keep-id:uid=1000,gid=1000", "--user", "1000:1000", "--security-opt", "label=disable",
        "-e", "CALLISTO_DENSITY=" + os.environ.get("CALLISTO_DENSITY", "compact"),
        "-v", f"{REPO / 'shell/triton'}:/triton:ro",
        "-v", f"{REPO / 'containers'}:/harness:ro",
    ]
    # With a GPU the compositor and the shell render on it; without, in software.
    if os.access("/dev/dri/renderD128", os.R_OK | os.W_OK):
        options += devlib.device_options("/dev/dri")
    return options


def start() -> None:
    """The container, reused if it is already the right one."""
    wanted = image()
    OUT.mkdir(parents=True, exist_ok=True)
    found = podman("inspect", "-f", "{{.State.Running}} {{.ImageName}} {{index .Config.Labels \"density\"}}",
                   CONTAINER, check=False, capture_output=True, text=True).stdout.split()
    density = os.environ.get("CALLISTO_DENSITY", "compact")
    if found == ["true", wanted, density]:
        return
    down()
    podman("run", "--detach", "--name", CONTAINER, "--label", f"density={density}",
           "--stop-timeout", "2", *run_options(), "-v", f"{OUT}:/out", wanted,
           # Waits, and reaps what the compositors leave behind.
           "sh", "-c", "trap exit TERM; while :; do sleep 3600 & wait $!; done",
           stdout=subprocess.DEVNULL)


def down() -> None:
    podman("rm", "--force", "--ignore", "--time", "2", CONTAINER, stdout=subprocess.DEVNULL)


def check(item: tuple[str, str, str], worker: int) -> bool:
    name, entry, page = item
    for old in (OUT / f"{name}.png", OUT / f"{name}.log"):
        old.unlink(missing_ok=True)
    done = podman("exec", CONTAINER, "python3", "-B", "/harness/shellrun.py",
                  name, entry, page, str(worker), check=False, capture_output=True, text=True)
    if done.returncode:
        print(f"FAIL {name}: the harness did not run\n{done.stdout}{done.stderr}")
        return False
    result = json.loads(done.stdout.splitlines()[-1])
    log = OUT / f"{name}.log"
    problems = devlib.log_problems(log.read_text(errors="replace"))
    why = []
    if not result["loaded"]:
        why.append("did not load")
    if result["died"] is not None:
        why.append(f"exited with {result['died']}")
    if result["blank"]:
        why.append("the screen is blank")
    if problems:
        why.append(f"{len(problems)} errors in the log")
    verdict = "FAIL" if why else "ok  "
    shot = OUT / f"{name}.png"
    print(f"{verdict} {name:24} {result['seconds']:4.1f}s  {shot.relative_to(REPO) if shot.exists() else ''}")
    if why:
        print(f"     {', '.join(why)} ({log.relative_to(REPO)})")
        for line in list(dict.fromkeys(problems))[:15]:
            print(f"     {line}")
    sys.stdout.flush()
    return not why


def check_all(names: list[str], jobs: int) -> bool:
    items = [target(name) for name in names]
    start()
    workers: Queue[int] = Queue()
    for worker in range(jobs):
        workers.put(worker)

    def one(item):
        worker = workers.get()
        try:
            return item[0], check(item, worker)
        finally:
            workers.put(worker)

    started = time.monotonic()
    with ThreadPoolExecutor(jobs) as pool:
        results = list(pool.map(one, items))
    failed = [name for name, passed in results if not passed]
    if len(items) > 1:
        print(f"==> {len(items) - len(failed)}/{len(items)} ok in {time.monotonic() - started:.1f}s")
    if failed:
        print(f"failed: {' '.join(failed)}", file=sys.stderr)
    return not failed


def watch(names: list[str], jobs: int) -> None:
    check_all(names, jobs)
    print("==> Watching shell/triton; Ctrl+C stops.", flush=True)
    seen = devlib.newest_change("shell/triton")
    try:
        while True:
            time.sleep(0.3)
            now = devlib.newest_change("shell/triton")
            if now != seen:
                time.sleep(0.2)  # let an editor finish writing
                seen = devlib.newest_change("shell/triton")
                check_all(names, jobs)
    except KeyboardInterrupt:
        pass


def window(name: str) -> None:
    runtime, wayland = os.environ.get("XDG_RUNTIME_DIR"), os.environ.get("WAYLAND_DISPLAY")
    if not runtime or not wayland:
        die("--window needs a Wayland session")
    _, entry, page = target(name)
    qs = "qs -c triton" if entry == "shell.qml" else f"qs -p /triton/{entry}"
    # sway as a window, the shell inside it. Quickshell reloads on save by itself.
    config = f"output * bg #111318 solid_color\\ndefault_border none\\nexec env QT_QPA_PLATFORM=wayland {qs}\\n"
    script = f"mkdir -p -m 700 /tmp/run && printf '{config}' > /tmp/sway.conf && exec sway -c /tmp/sway.conf"
    os.execvp("podman", [
        "podman", "run", "--rm", "--init", *run_options(),
        "-v", f"{os.path.join(runtime, wayland)}:/wl/socket",
        "-e", "XDG_RUNTIME_DIR=/tmp/run", "-e", "WAYLAND_DISPLAY=/wl/socket",
        "-e", "WLR_BACKENDS=wayland", "-e", f"CALLISTO_GALLERY={page}",
        image(), "sh", "-c", script,
    ])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("names", nargs="*", help="entry points or gallery pages")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--watch", action="store_true")
    mode.add_argument("--window", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--down", action="store_true")
    parser.add_argument("-j", "--jobs", type=int, default=min(4, os.cpu_count() or 1))
    args = parser.parse_args()

    names = args.names or everything()
    if args.list:
        print("\n".join(everything()))
    elif args.down:
        down()
    elif args.window:
        window(args.names[0] if args.names else "shell")
    elif args.watch:
        if not args.names:
            die("name what to watch: shell.py --watch power")
        watch(names, args.jobs)
    else:
        sys.exit(0 if check_all(names, args.jobs) else 1)


if __name__ == "__main__":
    main()
