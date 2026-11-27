# Design boards

The visual specification of the desktop (the Triton design: Material 3
Expressive shapes and springs, space-age livery, tasteful blur). One file per
screen or component set, drawn at 1646 × 1029 logical pixels (2880 × 1800 at
1.75×).

The tokens the code is built from are [`../design/tokens.json`](../design/tokens.json).

## Viewing

```sh
cd references && python3 -m http.server
```

Then open a `.dc.html` file through the server. `_runtime/` and `assets/` are
what the pages need to run; they are not part of the design.

## Boards

| Group | Boards |
|---|---|
| Overview | `Main`, `Adwaita` |
| Foundations | `Color`, `Type`, `Materials` |
| Components | `Controls`, `Containers`, `ComponentIndex` |
| Bar and panels | `BarStates`, `MediaBar`, `Notifications`, `OSD`, `QuickSettings` |
| Launch and switch | `Launcher`, `Overview`, `WindowSwitcher`, `WindowSwitcherStates`, `Clipboard`, `ClipboardStates` |
| Session | `Lock`, `Greeter`, `LoginStates`, `Power`, `PowerStates` |
| Settings and capture | `Settings`, `SettingsStates`, `Wallpaper`, `WallpaperStates`, `Screenshot`, `ScreenshotStates` |

## Principles

1. **Real estate first.** Tiled windows are square with no gaps. Radius, shadow
   and blur belong to things that float.
2. **Three materials.** Solid for content, Mica for chrome, Glass for floating
   things, Thick Glass for big panels over busy content. No glass on glass.
3. **Color from the wallpaper.** Primary is action and focus, tertiary is
   warmth, containers carry state. In the light scheme, primary is for fills,
   never text on a material.
4. **The wave is identity:** launcher button, avatars, album art, swatches,
   loading. Never decoration on controls.
5. **Springs, not durations.** Spatial springs may overshoot a little; effects
   springs never do. Reduce motion swaps both for short fades.
6. **Re-skin, never re-layout** GNOME and libadwaita apps.

The boards were drawn for another compositor and mention niri; Callisto uses
Hyprland. Where the boards disagree with each other, the decisions are in
[component-system §8](../docs/design/component-system.md).
