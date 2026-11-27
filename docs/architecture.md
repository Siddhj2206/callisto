# Architecture

Callisto OS is Debian 13 (trixie) plus backports, a Hyprland session, and a
shell and settings app written for it on Quickshell. Debian packages provide
the system; this repository provides the configuration, the shell and a few
small programs; apps come from Flathub.

## Repository

```
bin/          programs the OS ships (installed to /usr/local/bin)
configs/      system and session configuration, one folder per subject
shell/triton/ the shell and the Settings app (QML)
design/       tokens, fonts, logo and wallpaper: the source of visual values
live-build/   the ISO definition: package lists, hooks, `lb config`
containers/   the ISO builder and the headless shell harness
scripts/      build, test and code-generation tools
references/   the design boards
docs/         you are here
```

## From repository to image

`scripts/sync-configs.sh` copies the repository into
`live-build/config/includes.chroot/`, which live-build overlays onto the image.
That tree is generated and rebuilt from nothing every time. The script is the
map from each file here to its path on the image.

`scripts/build-iso.sh` runs it, then live-build inside the rootless podman
image from `containers/builder.Dockerfile`. The package lists are in
`live-build/config/package-lists/`; the one setup hook
(`config/hooks/live/010-callisto-setup.hook.chroot`) sets the OS identity,
creates the live user, enables services, and installs matugen and the Flatpaks.

## Session

```
greetd ─ live image: automatic login ─┐
       └ installed:  callisto-greeter ┴─ start-callisto ─ uwsm ─ Hyprland
                                                          ├ callisto-shell.service     the shell (qs)
                                                          ├ callisto-settingsd.socket  settings daemon
                                                          ├ callisto-clipboard.service cliphist
                                                          └ hypridle
```

`callisto-greeter` runs the shell's `greeter.qml` under its own small Hyprland
and falls back to `tuigreet` if that fails.

Hyprland is configured in Lua (`configs/hypr/hyprland.lua`, installed to
`/usr/share/callisto`). A user's own `~/.config/hypr/hyprland.lua` loads it and
may override it. Runtime dispatches use the Lua form too.

## The shell

`shell/triton/` is one Quickshell project with three entry points:
`shell.qml` (the desktop), `settings-app.qml` (Settings, its own process) and
`greeter.qml`. `gallery.qml` renders components with sample data and is left
out of the image.

```
tokens/       generated: colors, sizes, type, motion
foundations/  text, icons, materials, state layers, springs, presence
primitives/   buttons, sliders, fields, rows
patterns/     panels, popovers, cards, tiles, overlay windows
surfaces/     bar, launcher, lock, settings pages, ...
services/     state and system access, one concern per singleton
```

Imports go one way, from `tokens` towards `surfaces`. A surface is a view built
from components, plus a `...Host` file that owns the window and talks to
services. The rules are in
[design/component-system](design/component-system.md).

Quickshell registers a `qs.<folder>` module only for folders reachable from the
entry file's imports. This is why `gallery.qml` imports all of them.

Keybinds reach the shell through Quickshell IPC (`qs -c triton ipc call ...`).

## Settings and theming

```
Settings app ──► callisto-settingsd ──► ~/.config/callisto/settings.json
                        │
                        └─► callisto-apply ──► shell tokens, GTK, Qt, foot,
                            (+ matugen)        Hyprland, hypridle, gsettings
```

The daemon is the only writer of the store, and the engine is the only writer
of what is compiled from it. See
[design/settings-architecture](design/settings-architecture.md).

`design/tokens.json` is the other input. `scripts/generate-theme.py` turns it
into the QML under `tokens/` (and `Theme.qml`, `Icons.qml`), which is
committed; `make check` fails if the two drift.

## Small programs

| Program | Job |
|---|---|
| `start-callisto` | Session environment and rendering choice, then Hyprland through uwsm |
| `callisto-greeter` | Graphical login with a text fallback |
| `callisto-settingsd` | Settings store: validate, write, schedule applies |
| `callisto-apply` | Compile settings and tokens into each program's format |
| `callisto-settings` | Open Settings, one instance |
| `callisto-shot` | Screenshots and screen recording for the shell |
| `callisto-clip`, `callisto-clip-store` | Clipboard history on top of cliphist, with pins; skips secrets |

## Installer

Calamares copies the live filesystem to disk and then removes what belongs to
the live session. See [`../configs/installer/`](../configs/installer/README.md).

## Testing

| Command | Needs | Checks |
|---|---|---|
| `make check` | Python, shellcheck | Scripts, generated tokens, QML literals, contrast, settings daemon |
| `make shell-test` | podman | Every entry point and gallery page loads; screenshots in `.out/shell-all/` |
| `scripts/test-shell.sh --gallery <page>` | podman | One component group, to look at |
| `make smoke` | QEMU, KVM | The built ISO boots, no unit fails and the session is up; screenshot in `.out/iso/` |

## CI

`check` runs `make check` and `make shell-test` on every pull request. `iso`
builds the image, runs `make smoke`, reports which packages changed since the
last build of `main`, and keeps the ISO for a week; it also runs weekly, to
catch what moves upstream. Renovate (`renovate.json`) updates actions,
container base images and matugen.

Anything involving Hyprland behaviour, login, lock or installing is checked by
hand in a VM; the [roadmap](roadmap.md) records what was.
