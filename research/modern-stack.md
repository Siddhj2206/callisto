# Modern Wayland Desktop Stack Research (2025/2026) — Callisto OS integration notes

Research basis: Debian 13 (trixie) live ISO + Hyprland + Quickshell (Triton) + foot + Flatpak-only GUI apps, launched via greetd `initial_session` → `/usr/local/bin/start-callisto` → uwsm → Hyprland.

## ⚠️ CRITICAL PRELIMINARY FINDING: Hyprland is NOT in trixie main

**Hyprland does not exist in Debian 13 (trixie) main.** It was removed from testing in June 2025 ahead of the freeze ("the packaged version was behind upstream and would not be supported over the stable release's lifetime"). It is only available from **trixie-backports**:

- `hyprland 0.55.2+ds-1~bpo13+1` (as of late 2026), `apt install -t trixie-backports hyprland`
- `uwsm 0.26.7+ds-2~bpo13+1` — also backports-only
- `xdg-desktop-portal-hyprland`, `hypridle`, `hyprlock`, `hyprpolkitagent`, `hyprland-guiutils` — all backports-only
- Sources: [linuxiac April 2026](https://linuxiac.com/debian-13-stable-users-can-now-install-hyprland-from-backports/), [tracker.debian.org/pkg/hyprland](https://tracker.debian.org/hyprland), [Hyprland wiki Installation](https://wiki.hypr.land/getting-started/installation/)

**Consequence 1 — config language:** Hyprland ≥ 0.55 deprecates hyprlang (`hyprland.conf`) in favor of **Lua** (`hyprland.lua`). Backports ships 0.55.2, so **config must be written as `~/.config/hypr/hyprland.lua`** (or `/usr/share` defaults), using `hl.env()`, `hl.on("hyprland.start", ...)`, etc. Old `env =` / `exec-once =` / `bind =` syntax is legacy (0.54 and earlier). If Callisto pinned an older hyprlang-based config, it needs porting. Note: hyprlang configs are still parsed as a fallback in 0.55/0.56 but are deprecated and the wiki redirects to Lua.

**Consequence 2 — live-build:** you must enable trixie-backports in the live image's apt sources and pin/install with `-t trixie-backports`. Also note backports deps: one user reported needing `hyprland` + `hyprland-guiutils` installed in one transaction to satisfy `libxkbcommon` version constraints.

---

## 1. uwsm + systemd user session best practices

Source: [uwsm README](https://github.com/Vladimir-csp/uwsm) (canonical), [Hyprland wiki — Systemd startup](https://wiki.hypr.land/Useful-Utilities/Systemd-start), [Hyprland wiki — Systemd](https://wiki.hypr.land/configuring/extra/systemd).

### What uwsm is the correct answer to

uwsm wraps the compositor in proper systemd units: `wayland-wm@<compositor>.service` (in `session.slice`), activates `graphical-session-pre.target` / `graphical-session.target` / `xdg-desktop-autostart.target`, manages the environment lifecycle, and binds graphical session lifetime to the login session bidirectionally. **It sets `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `XDG_SESSION_TYPE` automatically** — you must NOT set them yourself.

### THE correct way to launch

- Non-DM context (greetd `initial_session`): what matters is that the command runs **inside the user's login session** on a tty with systemd user manager + user dbus already up (greetd does this via pam_systemd — same as a tty login). The command should be:

  ```
  exec uwsm start hyprland.desktop
  ```

  or, if shipping a custom wayland-session entry, `exec uwsm start -- <entry-id>.desktop`. Since Hyprland 0.53-era Debian packaging, the entry is `hyprland.desktop` (upstream renamed away from `hyprland-uwsm.desktop`; Debian ships both `/usr/share/wayland-sessions/hyprland.desktop` and `hyprland-uwsm.desktop` — the latter itself is `Exec=uwsm start -- hyprland.desktop`; do not point uwsm at an entry that itself calls uwsm).

- **Do not** `systemctl --user start` compositor units by hand, and do not launch `Hyprland` bare. `uwsm start` does extra critical work: saves login environment, starts `wayland-session-bindpid@<pid>.service` binding the graphical session to the login session lifetime, and execs `systemctl --user start --wait` itself.
- Alternative raw systemd invocation (what uwsm does internally, for reference):
  `exec systemctl --user start --wait wayland-session-envelope@<compositor>.target`

### Environment: where vars go (this is the #1 thing integrators get wrong)

- **Never** put Wayland/Hyprland vars in `/etc/environment` — leaks into all sessions (wiki warning).
- **Never** put session env vars in `hyprland.lua`/hyprlang `env=` when using uwsm. Instead:
  - `~/.config/uwsm/env` (or `env.d/*`) — theming, XCURSOR, toolkit variables. Format is shell: `export KEY=VAL`.
  - `~/.config/uwsm/env-hyprland` — `HYPR*` and `AQ_*` vars, e.g. `export AQ_DRM_DEVICES="/dev/dri/card0:/dev/dri/card1"`.
  - For a distro image, drop these into the XDG config/data hierarchy uwsm sources: `${XDG_CONFIG_HOME}:${XDG_CONFIG_DIRS}:${XDG_DATA_DIRS}` in increasing priority — i.e. you can ship `/etc/xdg/uwsm/env` or `/usr/share/uwsm/env` system-wide instead of per-user files. (Sourced in reversed order, increasing priority.)
- `HYPRLAND_INSTANCE_SIGNATURE` does **not** need manual export: Hyprland itself pushes vars into the systemd activation environment (it has native sd_notify + var management; controlled by `HYPRLAND_NO_SD_VARS`/`HYPRLAND_NO_SD_NOTIFY`). uwsm detects `WAYLAND_DISPLAY` appearing in the systemd activation environment and signals readiness. If a var is missing downstream, the mechanism is `uwsm finalize VAR1 VAR2` run from compositor autostart, plus `UWSM_FINALIZE_VARNAMES` / `UWSM_WAIT_VARNAMES` in env files — not manual `dbus-update-activation-environment`.
- **`dbus-update-activation-environment --systemd --all` is legacy/obsolete under uwsm.** That recipe is for non-uwsm sessions. If NOT using uwsm, the one-liner is `exec-once = dbus-update-activation-environment --systemd --all` (or in Lua: `hl.on("hyprland.start", function() hl.exec_cmd("dbus-update-activation-environment --systemd --all") end)`). Under uwsm, drop it entirely.
- Use **dbus-broker** as the dbus daemon if at all possible: it reuses the systemd activation environment, eliminating the dual-environment problem. With reference dbus-daemon, unsetting isn't possible and uwsm "cleans up" by emptying vars; full cleanup then requires `loginctl terminate-user ""`.
- What must end up in the systemd user manager environment for portals/services to work: `WAYLAND_DISPLAY`, `DISPLAY` (if xwayland), `XDG_CURRENT_DESKTOP`, `XDG_SESSION_TYPE`, `XDG_SESSION_DESKTOP`, `HYPRLAND_INSTANCE_SIGNATURE`, plus toolkit/cursor vars. uwsm's preloader computes the delta automatically; you don't curate the list manually. Transient session vars (`XDG_SEAT`, `XDG_SESSION_ID`, `XDG_VTNR` etc.) are deliberately NOT exported to activation env since uwsm 0.26 — they're passed via `EnvironmentFile=` to the compositor unit and `uwsm app` handles them.

### Launching apps: `uwsm app --`

- All `exec-once`/binds in the Hyprland config should be prefixed: `exec-once = uwsm app -- mycommand --arg` / `bind = SUPER, E, exec, uwsm app -- pcmanfm-qt.desktop` (hyprlang; Lua equivalent `hl.exec_cmd("uwsm app -- ...")` in the startup hook).
- Why: apps must land in `app-graphical.slice` / `background-graphical.slice` / `session-graphical.slice` as their own scopes/services, NOT as children inside the compositor unit. Children of the compositor unit get killed with the compositor in the wrong order, can interfere with the unit's notify socket, and get wrong cgroup resource treatment.
- XDG autostart is handled by systemd (`xdg-desktop-autostart.target`) automatically in a uwsm session — do not also manually spawn things that have autostart entries.
- `uwsm app` is python and can be slow for launchers; alternatives: `uwsm-app` (fast daemon client), `app2unit`. For fuzzel: `launch-prefix=uwsm app --`.

### Shutdown

- Use `uwsm stop`. **Never** Hyprland's `exit` dispatcher and never kill the process — that yanks the compositor from under clients and breaks ordered unit teardown (forced shutdown, corrupted state).
- Nuclear cleanup if units get inconsistent: `loginctl terminate-user ""`.
- Greetd note: since `uwsm start` replaces the login shell process, `uwsm stop` ends the login session too, which returns control to greetd — exactly what a live-iso greeter flow wants.

### systemd integration inside Hyprland itself

- `graphical-session.target` activation is now built into Hyprland automatically — remove any old custom `hyprland-session.target` units (`systemctl --user revert hyprland-session.target`) and remove manual systemctl lines from config ([wiki: Systemd](https://wiki.hypr.land/configuring/extra/systemd)).
- `HYPRLAND_NO_SD_VARS` / `HYPRLAND_NO_SD_NOTIFY` / `HYPRLAND_NO_SD_TARGET` exist only for exotic multi-compositor setups; do not set them.

---

## 2. xdg-desktop-portal-hyprland configuration

Sources: [XDPH wiki](https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland), [ArchWiki XDG Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal), [xdg-desktop-portal docs](https://flatpak.github.io/xdg-desktop-portal/docs/), [xdph issue #343](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/343), [xdph issue #415](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/415).

### Architecture

- **XDPH implements**: ScreenCast, Screenshot, GlobalShortcuts (and hyprland-specific bits). **It does NOT implement FileChooser, Settings, or most other interfaces** — `xdg-desktop-portal-gtk` is the mandatory companion, installed alongside.
- Backend resolution order (xdg-desktop-portal ≥ 1.18, which trixie has): `/usr/share/xdg-desktop-portal/hyprland-portals.conf` is picked because `XDG_CURRENT_DESKTOP=Hyprland`. Debian's hyprland package ships exactly this file. Content:

  ```ini
  [preferred]
  default=hyprland;gtk
  ```

  This means: try hyprland backend first for any interface, fall back to gtk. This is upstream's blessed default — fufexan (hyprwm maintainer): "Should be the default for Hyprland: `default=hyprland;gtk`".
- User/distro overrides go in `$XDG_CONFIG_HOME/xdg-desktop-portal/hyprland-portals.conf` or `portals.conf` (config hierarchy: `~/.config`, `/etc/xdg`, then data dirs). Per-interface overrides are a `[preferred]` section with lines like `org.freedesktop.impl.portal.FileChooser=kde`.
- `UseIn=` in `.portal` files is **deprecated** — superseded by portals.conf resolution, though still used as a fallback filter. Don't rely on it; don't hack `/usr/share/xdg-desktop-portal/portals/*.portal`.
- **The Settings interface must resolve to `gtk`** (it does with `default=hyprland;gtk` since xdph doesn't implement Settings). Regression xdph 1.4.0 (mid-2026): delegation of unimplemented interfaces broke; fix was ensuring gtk is in the chain. Debian backports xdph tracks 1.3.x-era; still, `default=hyprland;gtk` is the correct form.
- If portals mysteriously no-op with no errors: XDG env vars are wrong or missing from the activation environment (wiki: "If your desktop portal is malfunctioning for seemingly no reason (no errors), it's likely your XDG env isn't set correctly"). `systemctl --user status xdg-desktop-portal xdg-desktop-portal-hyprland` to debug. Portal services are dbus-activated and ordered after `graphical-session.target` — which is exactly why uwsm/graphical-session.target correctness matters. (The ArchWiki workaround of commenting out `PartOf=graphical-session.target` is a hack for broken sessions — don't do this; fix the session.)
- XDPH config file `~/.config/hypr/xdph.conf`:
  ```
  screencopy {
      max_fps = 60
      allow_token_by_default = false
      custom_picker_binary = "hyprland-share-picker"
  }
  ```
  Needs `qt6-wayland` installed or the share picker crashes (silent long app-launch delays are the symptom).

### Dark mode / appearance: THE modern mechanism

The canonical mechanism is the **Settings portal key `org.freedesktop.appearance color-scheme`** (uint: 0 = no preference, 1 = prefer dark, 2 = prefer light), defined in the [portal Settings spec](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html). Chain of custody:

1. **Source of truth in a non-GNOME session: gsettings/dconf key `org.gnome.desktop.interface color-scheme`** (`'prefer-dark'` / `'prefer-light'` / `'default'`). You set it with `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'`.
2. **xdg-desktop-portal-gtk reads that gsettings key** and re-publishes it as the portal `org.freedesktop.appearance color-scheme` value over D-Bus, including live `SettingChanged` signals. This works without any GNOME session — xdp-gtk is specifically the gtk/gsettings-shaped backend.
3. **Who consumes the portal key**: GTK4/libadwaita apps, Firefox, Chromium/Electron (prefers-color-scheme), Qt (when using a portal-aware platform theme), and crucially **all Flatpak apps** — the portal is one of the few things that crosses the sandbox boundary by design, which is why this exists at all ([GNOME blog: Dark Style Preference](https://blogs.gnome.org/alicem/2021/10/04/dark-style-preference), [Flatpak desktop-integration docs](https://docs.flatpak.org/en/latest/desktop-integration.html): "On Wayland, the active theme is exposed via the corresponding Settings portal").
4. Also set `gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'` (or your theme) — GTK3 apps on Wayland read theme name through the same xdp-gtk Settings portal ([TingPing: How GTK3 themes work in Flatpak](https://blog.tingping.se/2023/04/20/Themes-and-Flatpak.html)).

So the answer to "how do modern shells push dark/light preference": **your shell writes the gsettings key (or dconf write `/org/gnome/desktop/interface/color-scheme`), xdg-desktop-portal-gtk propagates it to everything, including flatpaks.** Requires `glib2`/`dconf` + `xdg-desktop-portal-gtk` installed and the Settings portal resolving to gtk. Verify with:

```
gdbus call --session --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.ReadOne org.freedesktop.appearance color-scheme
```

Quickshell/Triton can also read this key the same way to auto-follow, or drive it as the writer.

---

## 3. XDG_CURRENT_DESKTOP exact value

- Value: **`Hyprland`** (capital H, exactly). uwsm sets it automatically from the wayland-sessions desktop entry `DesktopNames`; do not override. Historically the session entry was the sole setter; if compositor detection comes up empty uwsm auto-adds the compositor binary basename.
- Portals: `hyprland-portals.conf` is selected when the **first** entry of `XDG_CURRENT_DESKTOP` (colon-separated list) lowercases to `hyprland`. If you append other names (e.g. `Hyprland:GTK`), resolution still uses per-name `<de>-portals.conf` lookup in order. Keep it plain `Hyprland` unless you know why.
- Qt: `XDG_CURRENT_DESKTOP` influences QPA platformtheme autoselection: `gnome`/`GTK`-ish sessions → gtk3 platformtheme; `KDE` → kde platformtheme. On `Hyprland`, Qt's autoselection picks **nothing useful** — which is precisely why you must set `QT_QPA_PLATFORMTHEME` explicitly (next section).

## 4. Qt theming in 2025/2026

Sources: [hyprqt6engine wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprqt6engine), [QGnomePlatform repo (archived)](https://github.com/FedoraQt/QGnomePlatform), [Jan Grulich: Qt theming in Fedora](https://jgrulich.cz/2023/08/22/qt-theming-in-fedora-workstation), [Noctalia docs](https://docs.noctalia.dev/noctalia/templates/official/gtk-qt).

- **QGnomePlatform is dead** — archived July 2026, final release notes: "last release of QGnomePlatform... users are suggested to use QGtkStyle from Qt upstream instead." **adwaita-qt/QGnomePlatform should not be shipped.**
- Options for `QT_QPA_PLATFORMTHEME` in a Hyprland session today:
  1. **`hyprqt6engine`** — hyprwm's official Qt6 theme provider (since Aug 2025), "replaces qt6ct, compatible with KDE Apps / KColorScheme." Set `QT_QPA_PLATFORMTHEME=hyprqt6engine`, configure `~/.config/hypr/hyprqt6engine.conf` (`theme:color_scheme` accepts qt6ct themes or KColorScheme paths, `icon_theme`, `style`, fonts). This is the Hyprland wiki's current recommendation ("use hyprqt6engine for qt6 apps" — master tutorial).
  2. **`qt6ct`** (or patched `qt6ct-kde` for correct KColorScheme handling of KDE apps) — the widespread community choice; `QT_QPA_PLATFORMTHEME=qt6ct` (Qt6 apps; for Qt5 apps use `qt5ct`, same env var — each Qt version picks its matching ct automatically).
  3. **`gtk3`** — Qt's built-in QGtk3Theme: reads GTK theme/settings via the Settings portal, gives you portal-driven dark mode for free but is GTK3-era in looks and limited. Note QGnomePlatform's final release deliberately stopped using the `gtk3` keyword to avoid conflicting with upstream QGtkStyle.
- For a distro shipping its own shell theme: **hyprqt6engine or qt6ct with a generated color scheme** is the modern answer. Since Triton's theme tokens are already generated, generate a qt6ct-format color scheme (it's a simple INI-ish palette) as part of the theme seeding, and set `QT_QPA_PLATFORMTHEME` in `uwsm/env`.
- **Quickshell itself**: it's a Qt6/QML app; it renders its own widgets and ignores widget styles, but it still honors `QT_QPA_PLATFORMTHEME` for dialogs/fonts. It is affected by the same env; there's no quickshell-specific theme mechanism beyond its own QML.
- `QT_WAYLAND_DISABLE_WINDOWDECORATION=1` still relevant if you don't want Qt CSD titlebars double-framing (server-side decorations in Hyprland). Optional taste.
- `QT_QPA_PLATFORM=wayland;xcb` — still the correct value (Wayland with X fallback). Qt6 defaults to wayland when available in most distro builds now, but explicit is harmless.

## 5. GTK theming modern way

- `~/.config/gtk-3.0/gtk.css` still works as a user-level CSS override for GTK3 (and GTK4 honors `~/.config/gtk-4.0/gtk.css`), but it's a hack layer — it does not theme libadwaita apps (they hardcode libadwaita styles regardless) and is not how dark mode should be driven.
- **Modern chain for GTK3/4 on Wayland** (non-GNOME):
  - `gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'` (or `Adwaita-dark`) — read by GTK3 apps **via the xdg-desktop-portal-gtk Settings portal on Wayland** ([ArchWiki Dark mode switching](https://wiki.archlinux.org/title/Dark_mode_switching): "For desktops running with Wayland, gsettings is queried. To query gsettings configuration, GTK requires the Settings XDG Desktop Portal, provided by xdg-desktop-portal-gtk").
  - `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'` — drives libadwaita/GTK4 dark switching + the portal appearance key.
  - **adw-gtk3** (the community GTK3 port of libadwaita's look) is what modern shells (Noctalia, etc.) standardize on for GTK3 apps so they match GTK4/libadwaita. Ships as both host theme and flatpak extension `org.gtk.Gtk3theme.adw-gtk3` / `org.gtk.Gtk3theme.adw-gtk3-dark`.
  - **Do not** set `gtk-application-prefer-dark-theme` or expect GTK4/libadwaita apps to follow `gtk-theme` — libadwaita apps ignore the theme name entirely and follow ONLY `color-scheme` (via portal). "Uncheck GTK4 in nwg-look" per Noctalia docs — don't try to force-theme libadwaita.
  - `settings.ini` files (`~/.config/gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`) matter mainly for cursor/font settings on systems where the portal path is broken; with xdp-gtk running, gsettings is the live source.
  - nwg-look is the standard tool to write all these consistently (it writes gsettings + ini files); on a distro image, seed the values directly instead.

## 6. Flatpak integration

Sources: [Flatpak sandbox permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html), [desktop-integration](https://docs.flatpak.org/en/latest/desktop-integration.html), [TingPing](https://blog.tingping.se/2023/04/20/Themes-and-Flatpak.html), hyprcursor wiki FAQ.

### Wayland sockets

- Apps that support Wayland natively should have `--socket=wayland` + `--socket=fallback-x11` (not bare `x11`). Most well-maintained Flathub manifests already do this; you generally don't need global overrides.
- Flatpak 1.17+ semantics note: `fallback-x11` no longer permits X11 in a Wayland session if `--nosocket=wayland` is set, and conditional permissions exist: `--socket-if=x11:!has-wayland` grants x11 only when there is no Wayland session — the cleanest "wayland-only, x11-if-needed" policy (flatpak in trixie is 1.16.x though — conditional flags require 1.17; check what ships; don't rely on `socket-if` for trixie's flatpak 1.16).
- For a pure-wayland enforcement: `flatpak override --user --socket=wayland --nosocket=x11 --nosocket=fallback-x11 <app>` — but test per-app; some Electron apps break. Do not apply globally by default.
- Electron flatpaks: `--env=ELECTRON_OZONE_PLATFORM_HINT=auto` per-app override is the sane default (Electron ≥ 28 handles it well; flatpak docs still call wayland "experimental" but in practice 2025-era Electron is fine).
- Env propagation: flatpak apps inherit the **session environment** as filtered — important vars like `XDG_CURRENT_DESKTOP`, `QT_QPA_PLATFORMTHEME` do pass through. Anything missing can be forced with `flatpak override --env=...`. Because your env lives in the systemd user manager, and flatpak session-helper is itself a user service, correct uwsm env propagation is doubly important.

### Theming permissions / propagation

- **On Wayland, themes reach flatpaks via the Settings portal, not filesystem holes.** The correct distro integrator setup is: working `xdg-desktop-portal-gtk` + gsettings keys + theme available inside the sandbox. No `--filesystem` overrides should be needed for dark mode.
- Theme availability inside the sandbox: flatpak auto-installs packaged GTK3 themes matching the host gsettings `gtk-theme` during `flatpak update` (since flatpak 0.10.1 it reads the host gtk-theme dconf key and pulls `org.gtk.Gtk3theme.<name>` if the remote has it). So: if you set theme to `adw-gtk3`, ensure `org.gtk.Gtk3theme.adw-gtk3` and `org.gtk.Gtk3theme.adw-gtk3-dark` get installed (preinstall them on the ISO). **You don't need any Gtk3theme extension for stock Adwaita** — it's built into the runtime. If using a custom theme, either package it as a flatpak extension or accept fallback to Adwaita inside sandboxes.
- If you must expose host theme dirs (e.g. custom non-flatpak'd theme, cursors, icons): `flatpak override --user --filesystem=~/.themes:ro --filesystem=~/.icons:ro` and additionally install themes/icons into BOTH `/usr/share/{themes,icons}` and `~/.themes`/`~/.icons` (hyprcursor wiki FAQ). Better: keep custom assets in `/usr/share` and expose `xdg-data/...` or use `--filesystem=/usr/share/icons:ro` style overrides sparingly. Prefer extensions.
- `xdg-config/gtk-3.0:ro` etc. overrides are only needed for the legacy CSS/ini path; not needed when the portal chain works. Avoid punching config holes — the ArchWiki/TingPing position is that filesystem access for theming "weakens the sandbox and reduces portability; instead, desktop environments should provide proper support for the Settings portal."
- Fonts: flatpak apps see host fonts via the fontconfig cache automatically for system-installed fonts (`/usr/share/fonts`); user fonts in `~/.local/share/fonts` are NOT visible — ship fonts system-wide (you control the image, so this is free).
- Icons/cursors: same logic — system-wide install = visible; user-local = invisible without overrides.
- **`flatpak update` cadence for theming:** the theme auto-install logic runs on install/update, so after changing `gtk-theme` you need one `flatpak update` for matching theme extensions to appear. On a live ISO, just preinstall.
- Dark mode for flatpaks, summarized: working Settings portal → nothing else needed for GTK4/libadwaita/Electron/Firefox. GTK3 flatpaks need the theme extension matching the gsettings name. Qt flatpaks (org.kde.Platform) follow their own platform theme inside the runtime — KDE runtime apps read the portal too in recent versions; for edge cases `QT_QPA_PLATFORMTHEME` passes into the sandbox but the theme plugin must exist inside the runtime (kde runtime has qt6ct-style plugins for some themes; don't count on it — most flatpak Qt apps are KDE apps that follow KColorScheme/portal nowadays).

## 7. Session environment variables: what's still needed in 2025

| Variable | Verdict |
|---|---|
| `XDG_SESSION_TYPE=wayland` | **uwsm sets automatically.** Never set manually. |
| `XDG_CURRENT_DESKTOP=Hyprland` | **uwsm sets automatically.** Never set manually. |
| `XDG_SESSION_DESKTOP=Hyprland` | uwsm sets automatically. |
| `QT_QPA_PLATFORM=wayland;xcb` | Still recommended explicit (Qt6 mostly defaults correctly, but explicit avoids edge cases with older Qt5 apps). |
| `QT_QPA_PLATFORMTHEME` | **Required** — `hyprqt6engine` or `qt6ct` (see §4). No autoselection exists for Hyprland sessions. |
| `QT_AUTO_SCREEN_SCALE_FACTOR=1` | Legacy Qt5-era; mostly obsolete with Qt6 wayland scaling. Skip unless Qt5 apps matter. |
| `QT_WAYLAND_DISABLE_WINDOWDECORATION=1` | Optional; kills Qt CSD. Taste. |
| `GDK_BACKEND=wayland,x11,*` | Largely obsolete — GTK4/GTK3 auto-prefer wayland. Harmless but unneeded. |
| `MOZ_ENABLE_WAYLAND=1` | **Obsolete** — Firefox has defaulted to Wayland when available since ~Firefox 121 (2023). Drop it. |
| `ELECTRON_OZONE_PLATFORM_HINT` | Still the correct modern var (`auto` or `wayland`) for Electron ≥ 28. Caveat: breaks Discord keybind capture when `wayland` (hyprland FAQ) — use `auto` or per-app exceptions. Note many Electron apps still default X11 without it. Alternative: `--ozone-platform-hint=auto` flag or `~/.config/electron-flags.conf` (not honored by all apps, notably VSCode). |
| `SDL_VIDEODRIVER=wayland` | Mostly obsolete — SDL2 ≥ 2.24 / SDL3 prefers wayland by default. Setting it can BREAK games that bundle ancient SDL. Wiki says set it but remove if issues. Recommendation: skip. |
| `CLUTTER_BACKEND=wayland` | Obsolete niche. Skip. |
| `XCURSOR_THEME` / `XCURSOR_SIZE` | Still needed for XCursor fallback path (GTK apps, xwayland). Set in uwsm env. |
| `HYPRCURSOR_THEME` / `HYPRCURSOR_SIZE` | If using hyprcursor format themes. Note `HYPRCURSOR_SIZE` leaked into xcursor sizing in some versions (issue #8713) — prefer `hyprctl setcursor` at runtime or keep sizes consistent. |
| `GDK_SCALE`/`GDK_DPI_SCALE` | Obsolete/broken on wayland. Never. |
| `NIXOS_OZONE_WL` | NixOS-only. Irrelevant. |

Where they go: `~/.config/uwsm/env` (or system-level `/etc/xdg/uwsm/env` / `/usr/share/uwsm/env`), `export KEY=VAL` format. NOT in hyprland.lua, NOT in /etc/environment.

## 8. Hyprland config modern practices (0.55 era = what trixie-backports ships)

- **Config is now Lua**: `~/.config/hypr/hyprland.lua`. Since 0.55 hyprlang is deprecated. Examples in the current wiki use `hl.env()`, `hl.on("hyprland.start", function() hl.exec_cmd("...") end)`, `hl.bind()`, `hl.windowrule()` etc. If Callisto has hyprlang config, it still parses in 0.55/0.56 as fallback but is deprecated — plan the port. (Note the wiki for 0.54 and earlier documents old syntax; use the versioned wiki at wiki.hypr.land/0.54.0/ if you must.)
- **Systemd integration is automatic** — remove `exec-once = systemctl --user start hyprland-session.target`, remove `dbus-update-activation-environment` lines, remove custom target units. Under uwsm all of this is doubly handled.
- `misc:disable_hyprland_logo` — still valid (and `misc:disable_splash_rendering`), in Lua: nested table config. For a branded distro, yes, disable both and ship your own wallpaper/shell.
- `uwsm app --` prefix for every exec/bind (see §1).
- layer rules / window rules syntax: 0.5x moved to `layerrule` with `match:namespace`-style matching in recent versions (rule syntax has been revised multiple times across 0.4x→0.5x; windowrulev2 merged into `windowrule` in 0.50+). Because you're writing rules for Quickshell layers: verify against the **versioned wiki for 0.55** rather than copying blog examples — this area churns every release. Since Quickshell sets its own layer namespaces, match on them.
- Color management: 0.5x added CM/HDR support (`cm` / render settings); defaults fine for SDR live ISO.
- Environment variables in config: don't (uwsm). Exception: truly compositor-internal vars can go in `~/.config/uwsm/env-hyprland`.
- Do NOT use the `exit` dispatcher for logout; bind logout to `uwsm stop` (e.g. `bind = SUPER SHIFT, M, exec, uwsm stop`).

## 9. Polkit agent

- Modern choice: **hyprpolkitagent** (hyprwm official, written in hyprtoolkit; in trixie-backports). Alternatives: polkit-kde-agent, polkit-gnome (dated GTK3 look), soteria.
- Autostart the correct modern way under uwsm: `systemctl --user enable --now hyprpolkitagent.service` — it's a proper systemd user unit ([wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprpolkitagent)). In the image build, `systemctl --global enable hyprpolkitagent.service` (enables for all users). Fallback per wiki: `exec-once = systemctl --user start hyprpolkitagent` in config. Binary path varies by distro (`/usr/lib/hyprpolkitagent/hyprpolkitagent`, `/usr/libexec/...`) — prefer the unit over the binary path.
- It is **required** (wiki: "specifically marked as a must have") — flatpak GUI apps, file managers mounting drives, etc. all need it.
- Config `~/.config/hyprpolkitagent/hyprpolkitagent.conf` optional; theming comes from `~/.config/hypr/hyprtoolkit.conf` palette — note this for Triton: hyprtoolkit dialogs won't follow your shell theme unless you write hyprtoolkit.conf too.
- Alternative worth knowing: some Quickshell-based shells implement their own polkit agent in QML — Triton could, but hyprpolkitagent is less work.

## 10. Other integration points distros get wrong

- **Cursor propagation** (the classic broken thing): three parallel paths must ALL be set consistently —
  1. hyprcursor: `HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE` (or `hyprctl setcursor` in autostart);
  2. XCursor fallback (Qt, Chromium, xwayland): `XCURSOR_THEME`/`XCURSOR_SIZE` env in uwsm env;
  3. GTK: `gsettings set org.gnome.desktop.interface cursor-theme '<name>'` + `cursor-size` (dconf write fallback).
  Flatpaks need xdp-gtk running + cursor available in a visible location: install cursors system-wide in `/usr/share/icons` AND mirror to `~/.icons` if you use the override route (FAQ). Cursor size is in **logical** pixels on Wayland — don't multiply by scale (KDE blog: cursor size problems explained). XCURSOR_SIZE applies to xwayland apps in physical px — mismatches here are the classic "cursor changes size over some windows" bug.
- **XWayland scaling**: Hyprland 0.4x+ has `xwayland:force_zero_scaling = true` as the standard fix so xwayland apps use wayland-side scaling (still valid in 0.5x). Pair with correct monitor scale config.
- **xdg-user-dirs**: run `xdg-user-dirs-update` once at first login (systemd user service does this if enabled; live ISOs often miss it — broken Documents/Downloads portals and file picker locations otherwise). Also relevant: `org.freedesktop.FileManager1` dbus service if you want "show in folder" to work from flatpak browsers — point it at your file manager.
- **hypridle/hyprlock/hyprpaper with a custom shell**: all optional. If Triton implements lockscreen/idle/wallpaper itself, skip them entirely. If not: hyprlock is the cleanest wayland-native locker (uses ext-session-lock), hypridle handles idle+dpms+lock triggering (systemd units, `systemctl --user enable`), hyprpaper is trivial wallpaper. For a live ISO, remember a locker is what protects the session on tty-switch away; also `uwsm`'s `ttyautolock` helper exists for locking when the tty loses focus — relevant since greetd sessions live on a real tty.
- **GNOME Keyring / secrets**: if any flatpak needs Secret Service (many do — passwords, tokens), you need `gnome-keyring` with PAM integration, which display managers normally wire up. greetd's `initial_session` may skip PAM password unlock (autologin/live user has no password anyway). Consider `gnome-keyring` with blank-password login keyring or accept the prompt. The Secret portal backend (`org.freedesktop.impl.portal.Secret=gnome-keyring`) is what flatpaks use.
- **Notification daemon is mandatory**: apps (Discord especially) freeze without one. dbus-activation usually suffices if a daemon is installed; for Triton — Quickshell has notification server support, so you can implement it in-shell; otherwise mako/dunst/swaync.
- **PipeWire/wireplumber** must be user services running before portal screencast use — standard on Debian; just don't let the live ISO session optimizations disable them.
- **`org.freedesktop.impl.portal.Secret`, permission store, OpenURI**: permission store is host xdg-desktop-portal internal; OpenURI comes from gtk backend in the `default=hyprland;gtk` chain. If "open in browser" from flatpaks misbehaves, check xdg-settings/xdg-mime default associations (`xdg-mime default firefox.desktop x-scheme-handler/https`) — a very common live-ISO miss.

---

## TOP 10 most impactful corrections for a distro integrator

1. **Hyprland is not in trixie main — it's backports-only, and it's 0.55.x, meaning the config language is Lua, not hyprlang.** Any `hyprland.conf`-based configuration and any docs/blog snippets with `env =`/`exec-once =` syntax are legacy. Decide: pin the backports version deliberately in the ISO build, port config to `hyprland.lua`.
2. **Under uwsm: never set XDG_* session vars, never use `env=`/`hl.env()` for session vars, never run `dbus-update-activation-environment`, never `systemctl --user import-environment` manually.** Put vars in `/etc/xdg/uwsm/env` + `env-hyprland` (shell `export` format) and let uwsm's preloader/finalize machinery handle propagation. Remove any such legacy lines — they actively cause the dual-environment desync bugs.
3. **Launch exactly as `exec uwsm start hyprland.desktop` from start-callisto** (after theme seeding; note theme seeding itself is better done as part of `uwsm/env` files or `environment.d` than imperative pre-launch scripting). Never bare `Hyprland`, never raw systemctl.
4. **Prefix all exec/binds with `uwsm app --`** so apps land in `app-graphical.slice` scopes rather than inside the compositor unit; enable XDG-autostart/systemd-unit autostarts instead of config `exec-once` where units exist (hyprpolkitagent: `systemctl --global enable`).
5. **Logout/shutdown via `uwsm stop` only** — never the `exit` dispatcher, never killing Hyprland. Binds and shell power menus must call `uwsm stop` (bonus: with greetd, login session ends and greeter returns).
6. **Ship both xdg-desktop-portal-hyprland AND xdg-desktop-portal-gtk, verify `default=hyprland;gtk` in `/usr/share/xdg-desktop-portal/hyprland-portals.conf`** (Debian ships it correct), and verify `graphical-session.target` actually activates (uwsm does it) — the portal stack silently no-ops otherwise. The Settings interface resolving to gtk is the linchpin of the entire theming story.
7. **Dark mode is a gsettings key + portal, not a theme name**: Triton writes `org.gnome.desktop.interface color-scheme` (prefer-dark/light) and `gtk-theme`; xdp-gtk broadcasts `org.freedesktop.appearance color-scheme` to everything including flatpaks. Verify with the `gdbus ... Settings.ReadOne` probe. Do not waste effort on `~/.config/gtk-3.0/gtk.css` hacks or `GTK_THEME` env for dark mode.
8. **Qt: use hyprqt6engine (or qt6ct) with `QT_QPA_PLATFORMTHEME` set in uwsm env — never QGnomePlatform/adwaita-qt (dead/archived), never rely on autoselection** (nothing useful is selected on `XDG_CURRENT_DESKTOP=Hyprland`). Generate the qt6ct/KColorScheme palette from Triton theme tokens at seed time.
9. **Flatpak dark-mode/theming needs zero sandbox holes when the portal chain works** — instead preinstall `org.gtk.Gtk3theme.adw-gtk3[-dark]` (if using adw-gtk3), install cursors/icons/fonts system-wide (`/usr/share`), and only then consider `--filesystem=~/.icons:ro`-type overrides as fallback. Set `ELECTRON_OZONE_PLATFORM_HINT=auto` per-app for Electron flatpaks rather than globally (Discord keybind breakage). Run `flatpak update` once after first setting the theme so theme extensions auto-install.
10. **Don't forget the boring glue**: a notification daemon must exist (or apps freeze), `xdg-user-dirs-update` must run once, xdg-mime default handlers must be set (https/browser), a polkit agent must autostart (`--global enable`), cursor must be set in all three channels (hyprcursor env + XCURSOR env + gsettings), and use **dbus-broker** as the dbus implementation so activation-environment cleanup actually works.
