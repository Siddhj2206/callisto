# Settings Wiring — Final State (2026-11-27, post-fix pass)

This supersedes settings-wiring-matrix.md. The earlier audit's PLACEBO/STORE-ONLY/UNWIRED
items were fixed in the night pass; verified in the sway harness (live screenshots)
and in QEMU against real ISO boots.

## WIRED end-to-end (verified)

### Appearance (the core loop)
- mode dark/light → engine stamps active_mode, shell switches scheme live, gsettings/foot/gtk/qt6ct follow at apply time. **Verified: light-mode repaint live in harness (bar RGB 249,249,255).**
- mode auto → time-of-day resolution (07–19 light) in BOTH shell (Theme.resolveMode) and engine (resolve_mode), consistent; minute timer re-flips external apps on boundary crossing.
- accent wallpaper → matugen extraction incl. generative-wallpaper seed colors (KIND_SEEDS). **Verified live in QEMU: bar re-themed orange on custom accent, blue on wallpaper extraction.**
- accent named seeds / custom hex (input field in panel) → matugen color scheme. Verified in harness (primary #A7F3BB for #8CD6A0 seed).
- contrast slider → matugen --contrast threaded through both scheme paths + cache keys.
- material solid/mica/glass → engine emits decoration.blur/shadow config.

### Input
- repeat rate/delay sliders (unit-mapped), repeat on/off (rate→0), keyboard layout chips (10 layouts), natural scroll, tap-to-click, pointer sensitivity → engine lua emission + live `hyprctl eval` (0.55+ dialect — keyword is dead in lua mode). Verified in harness.

### Power/Display
- power profile radios → powerprofilesctl. dimIdle/suspendIdle → hypridle.conf regenerated + SIGHUP.
- night light (settings + quicksettings tile) → hyprsunset temperature.
- display scale stops-slider → hl.monitor rule + live push; vrr → misc:vrr.

### Shell
- barMode cards, clock 12/24h, reduce motion (gated durations), showWindowTitle (center island), batteryWavyRing (wave-ring gauge), revealOnUrgent (4s bar flash), revealDelay (edge sensor timing), edge-reveal sensor strip.
- DND single source of truth in store.
- lockscreen notifications toggle gates lock rows.

### Sound/Network/Bluetooth
- volume sliders ↔ live pipewire (verified QEMU), device list real with active marking + selection.
- wifi switch/networks list/connect, bluetooth switch/devices — Quickshell.Networking/Bluetooth services.

### Apps
- default browser read live (xdg-settings); about hostname live.

## Descoped honestly (no fake UI)
- Displays arrangement canvas: caption says "arrives in a future update" — no drag lie.
- WindowsPanel center-column row removed (niri concept, meaningless in hyprland).
- +Greeter chip: wired to store key but greeter is live-autologin — effect lands with the installer path.

## Structural fixes
- 14 eager panels → single Loader.
- libglib2.0-bin added — gsettings/portal chain was absent from ISO.
- default callisto-user.lua in skel — first boot never errors on the module.
- foot.ini corrupted include path fixed.
- fuzzel/mako dropped — the shell is the launcher and the notification daemon.
- clipboard: real clipwatch daemon + wl-copy paste re-injection.
