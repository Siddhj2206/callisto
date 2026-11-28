# Third-party work

Callisto's own work is under [GPL-3.0-or-later](LICENSE). What is below is not
ours and keeps its own licence.

Callisto OS is assembled from other people's software. This lists what is
copied into this repository or fetched by name into the image. Everything else
comes from Debian and Flathub under its own licences; on an installed system
see `/usr/share/doc/*/copyright`.

## In this repository

| What | Where | Licence |
|---|---|---|
| Google Sans Flex | `design/fonts/GoogleSansFlex-*` | [OFL 1.1](licenses/OFL-GoogleSansFlex.txt) |
| Jost | `design/fonts/Jost-*` | [OFL 1.1](licenses/OFL-Jost.txt) |
| JetBrains Mono | `design/fonts/JetBrainsMono-*` | [OFL 1.1](licenses/OFL-JetBrainsMono.txt) |
| Material Symbols (Google), subsetted and renamed "Triton Symbols" | `design/fonts/TritonSymbols*` | [Apache 2.0](licenses/Apache-2.0-MaterialSymbols.txt) |
| Default keyboard shortcuts, after [dux-shell](https://github.com/duxlabs-dev/dux-shell) (Avenge Media) | `configs/hypr/keybindings.json` | [MIT](licenses/MIT-dux-shell.txt) |
| GTK and KDE color templates, after [dux-shell](https://github.com/duxlabs-dev/dux-shell) (Avenge Media) | `GTK_COLORS` and `kde_colors` in `bin/callisto-apply` | [MIT](licenses/MIT-dux-shell.txt) |
| *Triton (artist's impression)*, the wallpaper: [ESO/L. Calçada](https://www.eso.org/public/images/eso1015a/). Resized, blurred and dimmed copies are used by the boards and galleries | `design/wallpaper.jpg`, `references/assets/`, `shell/triton/gallery/assets/` | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| React and ReactDOM (Meta), used only to open the design boards | `references/_runtime/` | MIT |

## Patched

| What | Where | Licence |
|---|---|---|
| [Hyprland](https://github.com/hyprwm/Hyprland), Debian's package rebuilt with an upstream fix | `patches/hyprland/` | BSD 3-Clause |

## Fetched at build time

| What | Why | Licence |
|---|---|---|
| [matugen](https://github.com/InioX/matugen) upstream release binary, version and checksum in `configs/matugen.env` | Colors from the wallpaper | GPL 2.0; source at the same tag |
| Flatpaks listed in `live-build/config/package-lists/callisto.flatpaks.txt` | Apps | Each app's own |
