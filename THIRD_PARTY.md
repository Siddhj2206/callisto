# Third-party work

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
| GTK and KDE color templates, after [dux-shell](https://github.com/duxlabs-dev/dux-shell) (Avenge Media) | `GTK_COLORS` and `kde_colors` in `bin/callisto-apply` | [MIT](licenses/MIT-dux-shell.txt) |
| React and ReactDOM (Meta), used only to open the design boards | `references/_runtime/` | MIT |

## Fetched at build time

| What | Why | Licence |
|---|---|---|
| [matugen](https://github.com/InioX/matugen) 4.2.0, upstream release binary, pinned by checksum | Colors from the wallpaper | GPL 2.0; source at the same tag |
| Flatpaks listed in `live-build/config/package-lists/callisto.flatpaks.txt` | Apps | Each app's own |

## Not yet settled

- `design/wallpaper.jpg` (also in `references/assets/`) came with the design
  boards. Its author and licence are not recorded. **It needs one, or a
  replacement, before this repository or an image is published.**
