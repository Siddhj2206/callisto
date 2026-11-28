<div align="center">

<img src="design/logo/callisto-logo.svg" width="112" alt="">

# Callisto OS

A fast, quiet desktop on a Debian base: Hyprland, a shell and settings app
written for it, and apps from Flathub.

[![check](https://github.com/siddhj2206/callisto/actions/workflows/check.yml/badge.svg)](https://github.com/siddhj2206/callisto/actions/workflows/check.yml)
[![iso](https://github.com/siddhj2206/callisto/actions/workflows/iso.yml/badge.svg)](https://github.com/siddhj2206/callisto/actions/workflows/iso.yml)

</div>

Callisto, the moon, has one of the oldest surfaces in the Solar System. The
idea is the same: Debian stable underneath, and one carefully made desktop on
top.

**Status: early development.** It boots, installs and is usable in a virtual
machine. It has not been tried on real hardware, and there are no releases or
updates for its own files yet. The [roadmap](docs/roadmap.md) says exactly what
has and has not been checked.

## What's in it

- **Its own shell**, built on [Quickshell](https://quickshell.org): bar,
  launcher, quick settings, notifications, lock and login screens, overview,
  window switcher, clipboard, wallpaper picker, screenshots and recording.
- **A settings app** so that no configuration file has to be edited by hand.
- **Colors from the wallpaper**, carried through to GTK, Qt and the terminal,
  in light and dark.
- **An offline installer** (Calamares), UEFI and BIOS, with optional disk
  encryption.
- **Debian 13** with a few packages from backports; graphical apps as Flatpaks,
  Files excepted.

## Try it

You need rootless podman, and `/dev/kvm` to boot the result. Builds of
`main` can also be downloaded from the [iso workflow](https://github.com/siddhj2206/callisto/actions/workflows/iso.yml) for a week.

```sh
make iso      # build callisto-amd64.hybrid.iso
make run      # boot it
```

The live session logs in by itself; the user's password is `live`. Install from
the launcher.

| Key | Does |
|---|---|
| `Super` + `Space` | Launcher |
| `Super` + `Return` | Terminal |
| `Super` + `,` | Settings |
| `Super` + `I` / `N` / `V` | Quick settings / notifications / clipboard |
| `Super` + `Tab`, `Alt` + `Tab` | Overview, window switcher |
| `Super` + `B` | Show or hide the bar (it also appears at the top edge) |
| `Super` + `Shift` + `S`, `Print` | Screenshot |
| `Super` + `Escape` | Lock |
| `Super` + `Shift` + `E` | Power |
| `Super` + `Q` / `F` / `M` | Close / float / full screen |

## Working on it

```sh
make          # all commands
make check    # lint, generated files, contrast, daemon tests
make shell-test  # load every part of the shell, in a container
make vm       # boot the ISO headless with 3D, then make vm-push after a change
```

- [Contributing](CONTRIBUTING.md): setup, the rules, how changes are checked
- [Architecture](docs/architecture.md): how the pieces fit
- [Documentation index](docs/README.md)

## Credits and licence

Copyright © 2026 Siddhj2206.

Callisto is free software: you can redistribute it and modify it under the
terms of the [GNU General Public License](LICENSE), version 3 or any later
version. It comes with no warranty.

It stands on Debian, Hyprland, Quickshell and many others. Borrowed work keeps
its own licence; see [THIRD_PARTY.md](THIRD_PARTY.md).
