#!/usr/bin/env python3
"""Drive callisto-settingsd in a throwaway home, with stand-ins for the
programs it calls, and check what it writes and runs. No session needed."""

import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
failures = []


def check(name, condition):
    print(("ok   " if condition else "FAIL ") + name)
    if not condition:
        failures.append(name)


with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    home, bin_dir, runtime = tmp / "home", tmp / "bin", tmp / "run"
    for path in (home, bin_dir, runtime):
        path.mkdir()
    calls = tmp / "calls"
    for name in ("hyprctl", "gsettings", "systemctl", "flatpak"):
        stub = bin_dir / name
        # hyprctl is slow, so that changes can arrive during an apply.
        stub.write_text(f'#!/bin/sh\necho "{name} $*" >> {calls}\n' + ("sleep 0.2\n" if name == "hyprctl" else ""))
        stub.chmod(0o755)

    # The engine reads the system tokens from /usr/share; point it at the tree.
    engine_dir = tmp / "engine"
    engine_dir.mkdir()
    source = (REPO / "bin/callisto-apply").read_text()
    source = source.replace("/usr/share/callisto/tokens.json", str(REPO / "design/tokens.json"))
    source = source.replace("/usr/share/callisto/default-settings.json",
                            str(REPO / "configs/callisto/default-settings.json"))
    (engine_dir / "callisto-apply").write_text(source)
    shutil.copy(REPO / "bin/callisto-settingsd", engine_dir)

    env = {"HOME": str(home), "XDG_RUNTIME_DIR": str(runtime), "PATH": f"{bin_dir}:/usr/bin:/bin",
           "CALLISTO_TRIAL_SECONDS": "2"}
    daemon = subprocess.Popen([sys.executable, str(engine_dir / "callisto-settingsd")], env=env,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    store = home / ".config/callisto/settings.json"
    user_lua = home / ".config/hypr/callisto-user.lua"
    sock_path = runtime / "callisto/settingsd.sock"
    try:
        for _ in range(50):
            if sock_path.exists():
                break
            time.sleep(0.1)
        client = socket.socket(socket.AF_UNIX)
        client.connect(str(sock_path))
        lines = client.makefile("r")

        def send(request):
            client.sendall((json.dumps(request) + "\n").encode())
            return json.loads(lines.readline())

        def put(key, value):
            return send({"op": "set", "key": key, "value": value})

        def new_calls(wait=1.5):
            time.sleep(wait)
            text = calls.read_text() if calls.exists() else ""
            calls.write_text("")
            return text

        first = new_calls(3)
        check("applies everything on start", "hyprsunset" in first and "gsettings" in first)
        check("creates the store", json.loads(store.read_text()) == {"version": 1})
        check("no monitor rule before a scale is chosen", "hl.monitor" not in user_lua.read_text())

        check("accepts a shell key", put("shell.clockFormat", "12h")["ok"])
        check("a shell key runs nothing", new_calls() == "")

        put("input.repeatRate", 40)
        ran = new_calls()
        check("an input key pushes input", "repeat_rate = 40" in ran)
        check("and touches nothing else", "gsettings" not in ran and "hyprsunset" not in ran)

        check("apps may read the colors by default", "--filesystem=xdg-config/gtk-4.0:ro" in first)
        put("appearance.themeApps", False)
        check("and not once turned off", "--nofilesystem=xdg-config/gtk-4.0" in new_calls())

        for scale in (1.5, 1.0):
            put("display.scale", scale)
            ran = new_calls()
            check(f"scale {scale} is pushed", f"scale = {scale}" in ran)
            check(f"scale {scale} survives a restart", f"scale = {scale}" in user_lua.read_text())

        for rate in range(20, 31):
            put("input.repeatRate", rate)
        ran = new_calls()
        check("a burst becomes one apply", ran.count("hyprctl eval") == 1 and "repeat_rate = 30" in ran)

        put("input.repeatRate", 31)
        time.sleep(0.2)  # inside the slow apply
        put("input.repeatRate", 32)
        check("a change during an apply is not lost", "repeat_rate = 32" in new_calls())

        put("input.keyboardOptions", "grp:alt_shift_toggle,ctrl:nocaps")
        check("keyboard options reach the compositor",
              'kb_options = "grp:alt_shift_toggle,ctrl:nocaps"' in new_calls()
              and 'kb_options = "grp:alt_shift_toggle,ctrl:nocaps"' in user_lua.read_text())

        def try_mode(output, mode):
            return send({"op": "trial", "output": output, "mode": mode})

        new_calls()
        check("a mode can be tried", try_mode("Virtual-1", "1280x720@60.00")["ok"])
        ran = new_calls(0.8)
        check("and is shown at once", 'output = "Virtual-1", mode = "1280x720@60.00"' in ran)
        check("but not stored", "1280x720" not in store.read_text() and "1280x720" not in user_lua.read_text())
        check("it goes back by itself", 'output = "Virtual-1", mode = "preferred"' in new_calls(2))
        check("and then cannot be kept", not send({"op": "keep"})["ok"])
        try_mode("Virtual-1", "1600x900@60.00")
        check("a kept mode is accepted", send({"op": "keep"})["ok"])
        new_calls()
        check("and survives a restart", 'mode = "1600x900@60.00"' in user_lua.read_text())
        try_mode("Virtual-1", "800x600@60.00")
        send({"op": "revert"})
        check("revert returns to the kept mode", new_calls().rstrip().split("\n")[-1].count("1600x900") == 1)
        check("refuses a bad mode", not try_mode("Virtual-1", '1x1" })os.exit()--')["ok"]
              and not try_mode('a"b', "preferred")["ok"])

        user_keys = home / ".config/hypr/callisto-keys.lua"
        check("a changed shortcut is accepted", put("keyboard.shortcuts", {"launcher": "SUPER + D", "bar": ""})["ok"])
        ran = new_calls()
        check("and the compositor reloads", "hyprctl reload" in ran)
        check("only the differences are written", '["launcher"] = "SUPER + D"' in user_keys.read_text()
              and '["bar"] = ""' in user_keys.read_text() and "terminal" not in user_keys.read_text())
        command = """notify-send 'it works' "$HOME" \\ done"""
        check("a custom shortcut is accepted", put("keyboard.custom", [
            {"title": "Say", "keys": "SUPER + SHIFT + Y", "command": command}])["ok"])
        new_calls()
        check("its command is quoted for the shell and Lua", 'keys = "SUPER + SHIFT + Y", command = "uwsm app -- sh -c '
              in user_keys.read_text())
        for keys in ("A", "SHIFT + A", "SUPER + NotAKey", 'SUPER + "', "SHIFT + SUPER + A", "SUPER + SUPER + A"):
            check(f"refuses the shortcut {keys!r}", not put("keyboard.shortcuts", {"launcher": keys})["ok"])
        check("refuses a command with a newline", not put("keyboard.custom", [
            {"title": "x", "keys": "", "command": "a\nb"}])["ok"])

        bindings = json.loads((REPO / "configs/hypr/keybindings.json").read_text())
        shipped = {b["id"]: b["keys"] for b in bindings if not b.get("fixed")}
        check("the shipped shortcuts are valid ones", put("keyboard.shortcuts", shipped)["ok"])
        check("no two shipped shortcuts share keys", len({b["keys"] for b in bindings}) == len(bindings))
        lua = (REPO / "configs/hypr/hyprland.lua").read_text()
        names = set(re.findall(r'bind\("([a-z.]+)",', lua))
        for prefix, parts in (("workspace.", "12345"), ("workspace.move.", "12345"),
                              ("focus.", ("left", "down", "up", "right")), ("move.", ("left", "down", "up", "right"))):
            names |= {prefix + part for part in parts}
        check("Hyprland binds exactly the listed shortcuts", names == set(shipped))

        for key, value in (("input.keyboardLayout", 'us" })os.exit()--'), ("input.keyboardOptions", 'a" })'), ("display.scale", 9),
                           ("display.scale", True), ("nope.key", 1), ("appearance.mode", "blue")):
            check(f"refuses {key}={value!r}", not put(key, value)["ok"])
        reply = send({"op": "get"})
        check("get merges the defaults", reply["store"]["shell"]["barMode"] == "edge"
              and reply["store"]["shell"]["clockFormat"] == "12h")
        idle = (home / ".config/hypr/hypridle.conf")
        put("power.dimIdle", True)
        new_calls()
        check("display off is a Lua dispatcher",
              """hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'""" in idle.read_text())
        client.sendall(b"not json\n")
        check("survives a bad line", not json.loads(lines.readline())["ok"] and send({"op": "get"})["ok"])
        check("no temp files left", [p.name for p in store.parent.glob(".settings*")] == [])
    finally:
        daemon.terminate()
        output = daemon.communicate(timeout=5)[0]
    if failures:
        print(output)

sys.exit(1 if failures else 0)
