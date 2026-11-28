# Contributing

Read [`docs/principles.md`](docs/principles.md) first: changes are held to it.

## Setup

You need rootless podman, Python 3, `shellcheck` and, for the VM, `/dev/kvm`.
Nothing else comes from the host: the ISO builder, the shell harness and QEMU
are containers, built the first time they are needed. The first `make iso` also
compiles the [patched Hyprland](docs/architecture.md#patched-packages), which
takes a while.

```sh
make            # list the commands
make check      # run before every commit
make shell-test # before a pull request that touches the shell
make iso        # build the ISO
```

[`docs/architecture.md`](docs/architecture.md) explains where things are.

## Working on the shell

Two loops. Use the first for how a component looks and whether it loads, the
second for anything the compositor or the system takes part in.

### In a container (seconds)

```sh
make shell PAGE=power          # load one gallery page, or shell, greeter, settings-app
make shell-watch PAGE=power    # again on every save
make shell-window PAGE=power   # live, in a window on your desktop
make shell-test                # everything at once
```

Screenshots and logs are in `.out/shell/`. A page fails if it does not load,
comes out blank or logs an error. Look at the screenshot too: nothing can tell
that a surface merely came out wrong.

This runs on sway. Blur, workspaces, keybinds and the rest of Hyprland need the
VM.

### In the VM (the real session)

```sh
make vm          # boot the ISO headless with 3D, then push your tree onto it
make vm-push     # after a change; or make vm-watch
make vm-shot     # screenshot to .out/vm/shot.png
make vm-down
```

You need an ISO only once: `make iso`, or one downloaded from CI, named with
`ISO=path make vm`. `vm-push` lays what the image would hold from your tree over
the running system and restarts what the change touches. It reports QML and
Hyprland config errors, and exits non-zero on them. Packages, the setup hook and
the boot menu are not files it can push: those need `make iso`.

`scripts/vm.py` does the rest, which is what a script or coding agent drives:

```sh
scripts/vm.py key meta_l-spc           # keys, by QEMU's names
scripts/vm.py type 'settings'
scripts/vm.py click 960 540            # screenshot coordinates (1920x1080)
scripts/vm.py shot launcher            # .out/vm/launcher.png
scripts/vm.py shot boot --screen       # the emulated screen: boot, greeter, hangs
scripts/vm.py run 'hyprctl clients'    # in the session; `root` for root
scripts/vm.py log                      # the shell's journal
make vm-gpu                            # fails unless the guest renders on virgl
make vm-perf                           # shell startup, memory and idle CPU
```

With a `/dev/dri` render node on the host the guest gets 3D (virgl); without
one it renders in software. A live system forgets everything, so
`scripts/vm.py up --fresh` (about 20 seconds) is the way back to a clean one.
The machine has an agent that `up` passes in as a systemd credential; nothing
for development is on the image. Idle locking is stopped in this machine.

`make run` boots the ISO as shipped in a window, through its own boot menu.

## Design rules

The rules, in full in
[`docs/design/component-system.md`](docs/design/component-system.md):

- Sizes, colors, radii, fonts and durations come from tokens. Change
  `design/tokens.json`, then run `make tokens`. Never edit generated files.
- One component per concept. Compose before adding a new one.
- Views take properties. Only `...Host` files and services talk to the system.
- Surfaces enter and leave with motion, and respect reduce motion.
- The boards in `references/` are the design. Don't invent.

## Changing the image

- A file goes on the image only through `scripts/sync-configs.sh`.
- A package goes in `live-build/config/package-lists/` with a comment saying why.
- A file that must not survive installation goes in
  `configs/installer/live/live-only`.
- A downloaded binary is pinned by version and checksum (see
  `configs/matugen.env`), and listed in [`THIRD_PARTY.md`](THIRD_PARTY.md).

## Licence

Contributions are made under GPL-3.0-or-later, the licence of the project.
Anything brought in from elsewhere must be compatible with it and listed in
[`THIRD_PARTY.md`](THIRD_PARTY.md).

## Commits

[Conventional commits](https://www.conventionalcommits.org): `fix(installer):
...`, `feat(shell): ...`. Say why in the body when the diff doesn't.

Update [`docs/roadmap.md`](docs/roadmap.md) when you finish or find something,
and say how it was checked, and what was not.
