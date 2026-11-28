"""Run as root in the guest by `vm.py push`: lay the staged tree (a tar on
stdin) over /, and print what changed as JSON."""

import io
import json
import os
import pwd
import shutil
import sys
import tarfile

MANIFEST = "/run/callisto-dev/manifest.json"
# Entirely ours, so anything extra in it is a file the repository dropped.
OWNED = "etc/xdg/quickshell/triton"


def current(path: str, content: bytes, mode: int) -> bool:
    if os.path.islink(path) or not os.path.isfile(path) or os.stat(path).st_mode & 0o7777 != mode:
        return False
    with open(path, "rb") as file:
        return file.read() == content


def write(path: str, content: bytes, mode: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".push", "wb") as file:
        file.write(content)
    os.chmod(path + ".push", mode)
    os.replace(path + ".push", path)


def main() -> None:
    tar = tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()), mode="r:gz")
    names, changed = [], []
    user = pwd.getpwnam("user")
    for member in tar:
        if not member.isfile():
            continue
        name = member.name.removeprefix("./")
        content, mode = tar.extractfile(member).read(), member.mode & 0o7777
        names.append(name)
        if current("/" + name, content, mode):
            continue
        write("/" + name, content, mode)
        changed.append(name)
        # /etc/skel only reaches new accounts; the live one already exists.
        if name.startswith("etc/skel/"):
            own = os.path.join(user.pw_dir, name.removeprefix("etc/skel/"))
            write(own, content, mode)
            # The file, and any folder that had to be made for it.
            while own != user.pw_dir:
                os.chown(own, user.pw_uid, user.pw_gid)
                own = os.path.dirname(own)

    old = []
    if os.path.exists(MANIFEST):
        with open(MANIFEST) as file:
            old = json.load(file)
    for folder, _, files in os.walk("/" + OWNED):
        old += [os.path.join(folder, file).lstrip("/") for file in files]
    removed = sorted(set(old) - set(names))
    removed = [name for name in removed if os.path.isfile("/" + name)]
    for name in removed:
        os.remove("/" + name)
    for folder, dirs, files in os.walk("/" + OWNED, topdown=False):
        if not os.listdir(folder):
            shutil.rmtree(folder)

    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, "w") as file:
        json.dump(names, file)
    print(json.dumps({"changed": changed, "removed": removed}))


main()
