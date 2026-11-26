# Callisto

A reproducible, bootable **Debian 13 (trixie) live ISO** running a customized **Hyprland** Wayland desktop, implementing the **Triton (Material 3 Futura)** design identity.

Named for Callisto — the most heavily cratered, geologically ancient and unchanging surface in the Solar System — this distribution is built on the rock-solid foundation of Debian Stable.

## Status

🚧 Early development. See [`docs/roadmap.md`](docs/roadmap.md) for the execution plan.

## Components

| Component | Type | Source |
|---|---|---|
| Triton Status Bar (`shell/triton-bar`) | **Built from scratch** | Qt6/QML on [Quickshell](https://quickshell.outfoxxed.me) layer-shell toolkit |
| Fuzzel Launcher (`configs/fuzzel`) | **Customized existing** | [Fuzzel](https://codeberg.org/dnkl/fuzzel) styled to Triton tokens |
| Hyprland, Quickshell, PipeWire, etc. | **Reused upstream** | Debian `trixie` / `trixie-backports` packages |

## Design

All visual decisions derive from [`design/tokens.json`](design/tokens.json) — the Triton / Material 3 Futura token set. Reference boards live in [`references/`](references/).

**Triton principles:**

1. Tiled windows: zero gaps, zero rounding. Radius and blur belong to floating surfaces only.
2. Materials: Glass (70% alpha + compositor blur) for shell panels, Thick Glass (88%) for the launcher, solid for content. Never stack glass on glass.
3. The 9-lobe Triton wave is reserved for identity elements (launcher button, avatars) — never generic icons.

## Layout

```
design/         design tokens + wallpaper (single source of truth for visuals)
shell/          triton-bar — from-scratch Quickshell status bar
configs/        hyprland, fuzzel, greetd, gtk configuration
live-build/     Debian live-build configuration (ISO definition)
scripts/        build, sync, and QEMU run scripts
references/     Triton design boards (visual reference only)
docs/           roadmap and architecture documentation
```

## License

See individual component directories; upstream Debian packages retain their respective licenses.
