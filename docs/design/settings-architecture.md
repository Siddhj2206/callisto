# Callisto settings architecture — the no-dotfiles contract

**Contract**: the user never edits a config file. Every knob a user can
reasonably want lives in the Settings app; the app writes a single settings
store, and a *theme engine* compiles that store into whatever formats the
target programs need. Config files are compiler outputs, not interfaces.

## Layers

```
┌────────────────────────────────────────────────────┐
│ Settings app (Quickshell UI, floating window)      │  reads + writes
├────────────────────────────────────────────────────┤
│ Settings store  ~/.config/callisto/settings.json   │  single source of truth
├────────────────────────────────────────────────────┤
│ Theme engine  callisto-apply (python3, on system)  │  compiles store → formats
├──────────┬──────────────┬────────────┬─────────────┤
│ Triton   │ GTK 3/4      │ foot       │ hyprland    │  compiler outputs:
│ tokens   │ gtk.css      │ theme.ini  │ colors      │  regenerated on apply
└──────────┴──────────────┴────────────┴─────────────┘
            live reload: qs re-reads tokens.json on change;
            GTK reads gtk.css live; hyprland colors apply via hyprctl
```

Rules:

1. **The store is the only thing users' state lives in.** It is small,
   human-readable JSON, versioned (`"version": 1`). Everything else is
   regenerated; losing a compiled output loses nothing.
2. **The engine is idempotent and atomic** — writes go to temp files and are
   renamed. A crashed apply never leaves half-written state.
3. **Nothing in /usr is user-owned.** System defaults ship in
   `/usr/share/callisto/`; user overrides land in `~/.config/callisto/`.
   Update of the OS never touches user settings.
4. **Apply is live.** No "log out and back in" for anything visual. The few
   things that cannot apply live (kernel args) are surfaced as such in the UI.

## Who writes the store

`callisto-settingsd` (`bin/callisto-settingsd`) is the only writer.
It listens on `$XDG_RUNTIME_DIR/callisto/settingsd.sock` for JSON lines
(`{"op":"set","key":"appearance.mode","value":"light"}`, `{"op":"get"}`),
refuses keys and values outside its schema, writes the store atomically, and
after 120 ms of quiet runs the engine for the domains that changed (palette,
material, input, display, nightlight, idle, keys). `shell.*` and
`notifications.*` keys run nothing: the shell reads them from the store.

A display mode can leave a screen black, so it is not simply set:
`{"op":"trial","output":…,"mode":…}` shows it, and the daemon puts the old one
back after 15 seconds unless `{"op":"keep"}` arrives.

Keyboard shortcuts are listed once, in `configs/hypr/keybindings.json`.
Settings reads that list and the image build turns it into
`/usr/share/callisto/hypr/keys.lua` for `hyprland.lua`. The store holds only
what the user changed (`keyboard.shortcuts`, `keyboard.custom`), compiled to
`~/.config/hypr/callisto-keys.lua`, so an update can add shortcuts.

A new setting needs a schema entry in the daemon, and a domain if something
outside the shell must follow it. `scripts/test-settingsd.py` exercises the
daemon without a session.

## Panels (from the Settings board, mapped to backends)

| Panel group | Panel | Backend | Applies how |
|---|---|---|---|
| Connect | Network | NetworkManager (nmcli/dbus) | system service, live |
| Connect | Bluetooth | bluez (dbus) | system service, live |
| Devices | Displays | hyprctl/monitors | hyprctl eval, live |
| Devices | Sound | wireplumber/pipewire (dbus) | live |
| Devices | Keyboard | hyprland input section | hyprctl eval, live |
| Devices | Shortcuts | settings store → hyprland binds | hyprctl reload |
| Devices | Mouse & touchpad | hyprland input section | hyprctl keyword, live |
| Devices | Power | power-profiles-daemon, hypridle | dbus + config, live |
| Triton | Appearance | settings store → theme engine | live |
| Triton | Bar & Shell | settings store → qs reload | live |
| Triton | Windows | settings store → hyprctl | live |
| Triton | Notifications | settings store → qs reload | live |
| System | Apps | flatpak CLI | live |
| System | Users | accountservice (dbus) | live |
| System | About | read-only | — |

Reference for what belongs in each panel: gnome-control-center's grouping
translated into Triton's navigation. Anything gnome-control-center has that
Triton doesn't (printers, sharing, online accounts) is out of scope for v0.1
but the panel structure must not preclude them.

## Store schema (v1)

The shipped defaults, with every key, are
[`configs/callisto/default-settings.json`](../../configs/callisto/default-settings.json);
what each key accepts is `SCHEMA` in `bin/callisto-settingsd`.

The store covers *user preference*. Machine state (volume level, last wifi)
lives in the system services themselves — settings reads it live, it is never
persisted in the store.

## Theme engine outputs

| Output | Path | Consumer |
|---|---|---|
| Triton tokens | `~/.config/callisto/tokens.json` | the shell reads this over the system copy when present (`ThemeSync`) |
| GTK4/GTK3 css | `~/.config/gtk-4.0/gtk.css` | flatpak gtk apps pick it up via gtk settings |
| Qt colors | `~/.config/qt6ct/`, `kdeglobals` | Qt apps from Debian |
| foot colors | `~/.config/callisto/foot-theme.ini` | foot.ini `include=` |
| hyprland colors | `~/.config/hypr/callisto-user.lua` | hyprland.lua `require` |
| shortcuts | `~/.config/hypr/callisto-keys.lua` | hyprland.lua `require` |
