# Contributing

Read [`docs/principles.md`](docs/principles.md) first: changes are held to it.

## Setup

You need rootless podman, Python 3, `shellcheck` and, to try an image, QEMU
with KVM. Nothing is built with the host's packages.

```sh
make            # list the commands
make check      # run before every commit
make shell-test # before a pull request that touches the shell
make iso        # build the ISO
make run        # boot it
```

[`docs/architecture.md`](docs/architecture.md) explains where things are.

## Working on the shell

```sh
make shell-test                          # does it load?
scripts/test-shell.sh --gallery power    # look at one group of components
scripts/test-shell.sh --nested           # live, in a window
```

Look at the screenshot, not only the exit code: the headless harness cannot
tell that a surface came out wrong.

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
