# What goes into a proper daily-driver desktop Linux distribution

**Research date:** 2026-11-26 · **For:** Callisto (Debian 13/trixie live ISO, Hyprland + Quickshell shell)
**Method:** primary sources — the actual Omarchy package list and install scripts (github.com/basecamp/omarchy `master` as of today), the Fedora F41 "tuned replaces power-profiles-daemon" System-Wide Change page, Fedora Workstation/Sway spin composition, CachyOS and pmOS community practice. Debian package availability verified live against packages.debian.org/trixie (all Hyprland-ecosystem packages listed below returned HTTP 200 in trixie today).

The central finding: **lean-ness is not about fewer components, it's about exactly one component per job.** Every subsystem below has a canonical single-tool answer in 2025–26. Bloat comes from shipping two tools for one job (both NM and systemd-networkd active, both ppd and TLP, both hyprpaper and a full GNOME settings daemon), or from pulling in a desktop environment's infrastructure you don't use. Omarchy — our strongest reference — is not actually "minimal"; it's *curated*: full printing, full LibreOffice, full multimedia codecs, zero GNOME/KDE services.

---

## 1. Power management

### The ppd / tuned-ppd / TLP question

- **power-profiles-daemon (ppd)** is the de-facto standard D-Bus API (`net.hadess.PowerProfiles`) that desktops and shells talk to. Three profiles: power-saver / balanced / performance, implemented via `platform_profile`, Intel/AMD p-state. Simple, stateless, small C daemon.
- **tuned-ppd** is a compatibility shim from Red Hat's `tuned` project that exposes the same ppd D-Bus API but executes tuned profiles. **Fedora made tuned-ppd the default in Fedora 41** for Workstation, KDE and Budgie — explicitly because it gives power users a much wider range of tunable profiles while GNOME/KDE front-ends work unmodified (https://fedoraproject.org/wiki/Changes/TunedAsTheDefaultPowerProfileManagementDaemon). Mapping of the three ppd profiles to tuned profiles is configurable in `/etc/tuned/ppd.conf`.
- **TLP** overlaps with *both* and **conflicts**: TLP ships with `ppd.service` explicitly masked/conflicting in its docs, and running TLP alongside ppd or tuned produces competing writes to the same sysfs knobs (CPU governor, PCIe ASPM, USB autosuspend). Pick exactly one layer. TLP's niche is deep laptop battery optimization beyond what profiles express; its cost is a large rule-driven daemon that fights every other power tool.
- **Omarchy ships `power-profiles-daemon`** (verified in `install/omarchy-base.packages`), plus per-hardware extras: `thermald` (Intel thermal), `lpmd` (Intel low-power mode daemon), ASUS/Apple/Framework-specific fix scripts, and Wi-Fi powersave udev rules. Notably Omarchy has install-time fixes for ppd (`fix-powerprofilesctl-shebang.sh`) and custom powerprofilesctl polkit rules so the shell can switch profiles without password prompts.

**Verdict for Callisto:** ship **power-profiles-daemon** (trixie: `power-profiles-daemon`). It is the API everything expects, it's tiny, and tuned's extra flexibility is irrelevant to a curated shell. Do **not** ship TLP. Do not ship tuned-ppd unless you later want per-device tuning depth; if you do, it's a drop-in replacement, not an addition. **Uncertainty:** Fedora may have switched back from tuned-ppd after regressions (unconfirmed — couldn't verify post-F41 status); irrelevant for us since ppd is the right choice regardless.

### Supporting power infrastructure (all essential)

| Component | Why | Trixie package |
|---|---|---|
| UPower | battery/charge-state D-Bus API every shell widget reads | `upower` |
| logind config | lid switch, power button, suspend policy live here; Hyprland setups universally configure `HandleLidSwitch`, `HandlePowerKey`, idle action. Omarchy explicitly *ignores* the power button (`ignore-power-button.sh`) so the shell owns shutdown UX | `systemd` (edit `/etc/systemd/logind.conf` or drop-ins) |
| thermald | Intel-only thermal management; harmless on AMD, real value on modern Intel | `thermald` |
| suspend/hibernate | default s2idle/deep handled by kernel; distro job is correct swap sizing + `resume=` if hibernate offered; for a live ISO, hibernate is out of scope — suspend-then-nothing is fine. Memory-safety: hibernate on encrypted systems needs encrypted swap — punt initially | — |
| auto-cpufreq, cpupower GUIs, powertop-as-service | **avoid** — third power-management writers fighting ppd | — |

Fedora Workstation default stack in 2025–26 for comparison: ppd (via tuned-ppd) + UPower + thermald on Intel, nothing else. That confirms the minimal set.

---

## 2. Session / desktop infrastructure

This is where Hyprland distros most often ship broken or duplicated pieces. Canonical 2025–26 answers, all confirmed in Omarchy's package list and present in trixie:

| Job | Canonical tool | Trixie package | Notes |
|---|---|---|---|
| polkit agent | **hyprpolkitagent** (Omarchy currently uses `polkit-gnome`/`polkit-ekiga` lineage; hyprpolkitagent is the Hyprland-native successor and in trixie) | `hyprpolkitagent` (+ `polkitd`) | exactly one agent must autostart — duplicates are a classic breakage. Omarchy lists `polkit-gnome`; either works, but prefer the hyprland one for theming consistency. |
| xdg-desktop-portal backend | **xdg-desktop-portal-hyprland** for screencast/screenshot + **xdg-desktop-portal-gtk** as fallback for file chooser etc. | `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` | Omarchy ships exactly this pair. Config via `~/.config/xdg-desktop-portal/hyprland-portals.conf` or `/usr/share/xdg-desktop-portal/portals`. Do NOT install portal-gnome or portal-kde. |
| keyring/secrets | gnome-keyring, PAM-unlocked at login, SSH agent component | `gnome-keyring`, `libsecret` | required by Chromium/Firefox password stores and countless apps. Omarchy ships both. Init in uwsm/pam. There is no good lighter alternative (KWallet is heavier, `secret-service` daemons besides gnome-keyring are niche). |
| screen lock | **hyprlock** using `ext-session-lock-v1` (compositor-enforced, secure even if lock process crashes) | `hyprlock` | never rely on xdg-screensaver hacks |
| idle management | **hypridle** — native, per-listener timeouts driving hyprlock, dpms, suspend | `hypridle` | swayidle is the older alternative; don't ship both |
| clipboard persistence | **wl-clip-persist** (keeps clipboard alive after source app exits — a famous papercut) + cliphist for history if desired | `wl-clip-persist`, `cliphist` | Omarchy does not currently ship clip persistence (users complain); we should. `wl-clipboard` for CLI copy/paste |
| screenshots | grim + slurp, satty for annotation (Omarchy: same trio) | `grim`, `slurp`, `satty` | wire through portal too — some apps insist on portal screenshots |
| screen recording | gpu-screen-recorder (Omarchy) or wf-recorder; OBS for heavy use | `gpu-screen-recorder` *(verify in trixie — see uncertainties)*, `obs-studio` | portal + PipeWire capture is the future-proof path |
| OSD conventions | **swayosd** (brightness/volume on-screen display, daemon + client) — Omarchy uses it | `swayosd` | needs udev/input-group setup for brightness keys (Omarchy: `input-group.sh`) |
| notifications | mako or a Quickshell-native notification server | `mako` | since Callisto has a custom Quickshell shell, implement notifications in Quickshell eventually; mako as bootstrap |
| session launcher | **uwsm** — universal wayland session manager; puts session in systemd user units, fixes XDG env propagation, is what Hyprland docs recommend | `uwsm` | Omarchy ships it. This is genuinely important for correct `$XDG_SESSION_TYPE`/`systemd --user` semantics. |
| display manager | greetd+tuigreet, or SDDM | `greetd`, `sddm` | for a live ISO you mostly autologin; choose for installed-mode. Omarchy uses SDDM. Fedora Sway uses greetd. Lean answer: greetd. |

---

## 3. Audio / video

- **PipeWire + WirePlumber** is non-negotiable and universal in 2025–26 (Fedora since F34, everything since). Trixie: `pipewire`, `pipewire-audio` (metapackage pulling pipewire-pulse + wireplumber), `wireplumber`, `pipewire-alsa`. **Important:** enable user services — in Debian, `pipewire`, `pipewire-pulse`, `wireplumber` run as systemd user units; uwsm-managed sessions handle this correctly. NoPulseAudio, no JACK daemon by default (pipewire provides the JACK ABI via `pipewire-jack` if needed).
- **Bluetooth audio:** `bluetoothd` (`bluez`) + `libspa-0.2-bluetooth` for the PipeWire side. **Modern high-quality codecs (AAC, LDAC, aptX where licensable) need `libspa-0.2-codec-bluez5` in Debian** — split out for patent reasons; it's in non-free-firmware/main depending on version — *verify*. This is a classic omission: distros ship BT audio that pairs but sounds terrible because only SBC is available. GUI/TUI: Omarchy ships `bluetui` (TUI) — a Quickshell BT panel talking to bluez over D-Bus is the better long-term answer.
- **Camera:** works if `pipewire` + libcamera (`libcamera0.x`) + v4l2loopback-dkms are present; the modern pain point is Intel IPU6/IPU7 MIPI cameras needing vendor libs (Omarchy has a dedicated `ipu7-camera.sh` fix script — it's *that* broken upstream). Baseline: ensure PipeWire camera support is enabled and portal camera access works; accept that some laptop cameras are unsalvageable on mainline.
- **video playback/codec:** `mpv` + ffmpeg with full codec set. Fedora users must jump through RPM-Fusion hoops for H.264; **Debian trixie ships full ffmpeg in main** — a real advantage for Callisto. Hardware accel: `intel-media-driver`/`libva`/`mesa` vulkan as appropriate.

---

## 4. Network

- **NetworkManager**, single source of truth. Trixie: `network-manager`. Modem support: `modemmanager` only if targeting WWAN (skip — bloat for most users, but cheap).
- **iwd backend:** NM supports `wifi.backend=iwd` — faster roaming, better enterprise Wi-Fi. **Omarchy ships iwd and uses it.** Fedora still defaults to wpa_supplicant backend. Recommendation: ship `iwd`, set backend=iwd in NM config. Bonus: `impala` (Omarchy's pick) is an iwd TUI — in trixie. Standalone iwd without NM is the more radical lean choice but breaks VPNs and user expectations — don't.
- **GUI/applet strategy:** `network-manager-applet` (nm-applet/nm-connection-editor) exists in trixie but is GTK3-tray-era. Since Callisto has a Quickshell shell, the right move is shell-native network controls over NM's D-Bus API; nm-applet as fallback only. Omarchy uses impala (TUI) + shell integration.
- mDNS: `avahi-daemon` + `nss-mdns` — ship it (Omarchy does); needed for printer discovery, KDE Connect/localsend, `.local` hostnames.
- Firewall: Omarchy ships `ufw` — optional; a live ISO doesn't need a host firewall enabled by default (nothing listening), but having ufw present-but-inactive is harmless and expected by some users.

---

## 5. Input & display

- **Brightness:** `brightnessctl` (works for backlight + leds, no daemon, needs user in `video` group or udev rules — Omarchy does the input-group dance). Trixie: `brightnessctl`.
- **Night light:** **hyprsunset** — Hyprland-native, compositor-level color temperature via a small daemon; Omarchy uses it. Trixie: `hyprsunset`. gammastep is the wlroots-agnostic alternative (`gammastep` in trixie); hyprsunset is the correct pick for Hyprland. Don't ship both.
- **Touchpad gestures:** libinput handles the hardware; `libinput-gestures` or fusuma for gesture→action mapping. Better: Hyprland 0.41+ has **native gestures** (workspace swipe) — use those, skip extra daemons.
- **Input methods:** fcitx5 stack (`fcitx5`, `fcitx5-gtk`, `fcitx5-qt`) — Omarchy ships it because CJK input is non-negotiable for a big fraction of desktop users. Include; it idles harmlessly for non-CJK users. Essential but invisible infra: correct `GTK_IM_MODULE`/`QT_IM_MODULE`/XMODIFIERS env in the uwsm session.
- **xwayland:** `xwayland` must be present (many apps still need it) — but nothing else X11.
- per-monitor config: kanshi or nwg-displays for profile-based monitor setup; Hyprland's own config covers most needs. Optional.

---

## 6. Printing — include or not?

Every "lean" distro faces this. The evidence:

- **Omarchy — yes, full CUPS**: `cups`, `cups-browsed`, `cups-filters`, `cups-pdf`, `system-config-printer`, plus an install-time `printer.sh` hardware script. For an "opinionated minimal" distro that's a loud statement: printing is basic desktop infrastructure, and print-to-PDF alone justifies it.
- **Fedora Workstation — yes** (CUPS + ipp-usb for driverless USB printers).
- **pmOS / truly minimal spins — no**, but they're targeting phones and tinkerers.

**Verdict: include CUPS, but configure driverless-first.** Ship `cups`, `cups-browsed`, `cups-pdf` (PDF printing is used constantly even by the printerless), `ipp-usb` (driverless USB printing — modern, replaces vendor drivers), `system-config-printer` or better a shell-native print settings portal. Skip: vendor driver blobs (hplip full GUI stack is heavy — install on demand), samba-printing server bits. Cost is small (~50 MB), payoff is a desktop that "just works" in the one domain users absolutely cannot debug themselves.

---

## 7. Update/upgrade model for a Debian-based live distro

Callisto is a live ISO. How derivatives square "live" with "daily driver":

- **Persistence:** classic Debian Live model = squashfs + optional persistence partition (overlay on ext partition labeled `persistence` with `persistence.conf`). Debian-live supports this natively (`live-boot`, `live-config`). Users who *install* get a normal system; the live session itself can be optionally persistent. This is proven infrastructure — use Debian's own live-build rather than reinventing.
- **Install path matters most:** the overwhelming majority of serious users will install to disk (Omarchy is install-only, no live session at all — interesting precedent). Decide early whether Callisto is (a) live-with-installer (Calamares or debian-installer) or (b) install-medium-only. For a 6-day deadline: live session + Calamares is the Debian-conventional combo.
- **Package UX:** apt + a curated app layer. GNOME Software / KDE Discover are heavy; `synaptic` is ugly but honest. Realistic options: (1) apt CLI + good docs (Omarchy model — Arch users are expected to use pacman/yay); (2) flatpak+Flathub for desktop apps where Debian versions lag (browsers especially — but Chromium/Firefox-esr in trixie is fine). **Flatpak inclusion decision:** Omarchy excludes flatpak entirely and users either love the purity or hit walls with apps not in Arch repos. For Debian, stable-repo staleness is a real issue by 2027; recommend: install `flatpak` + `xdg-desktop-portal` integration but **no flatpaks preinstalled** — presence without bloat, escape hatch preserved. Mark as optional in the table.
- **Release model:** trixie point releases + your own repo for Quickshell shell + backports of Hyprland-ecosystem packages if trixie's versions age. Flag: Hyprland moves fast and trixie freezes — you'll eventually maintain a small overlay repo. Plan for it now even if it's empty at launch.

---

## 8. What Omarchy includes and excludes

Directly from `install/omarchy-base.packages` and `install/config/all.sh` (master branch, fetched today):

**Includes (notable):**
- Core Hyprland stack: `hyprland`, `hypridle`, `hyprlock`, `hyprpicker`, `hyprsunset`, `swaybg`, `uwsm`, `waybar` (default bar), `mako`, `swayosd`, `xdg-desktop-portal-hyprland` + `-gtk`, `polkit-gnome`, `hyprland-preview-share-picker`.
- Full desktop apps: **Chromium** (not Firefox — the opinionated browser pick), LibreOffice-fresh, Obsidian, Signal, Spotify, Nautilus + sushi + gvfs (mtp/nfs/smb), Evince, mpv, imv, kdenlive, OBS, pinta, gnome-calculator, gnome-disk-utility.
- Full dev workstation: neovim (own config), docker, mise, rust/ruby/llvm/dotnet, github-cli, lazygit/lazydocker, 1Password, Claude Code (!). This is unabashedly a *developer* distro — hence DHH.
- Terminal ecosystem: alacritty, starship, zoxide, eza, bat, fzf, fd, ripgrep, tmux, btop.
- TUIs instead of GUIs where possible: `impala` (wifi), `bluetui` (bluetooth), `wiremix` (pipewire mixer).
- Full printing (see §6), full fonts incl. CJK + emoji, fcitx5 input methods, plymouth boot splash, avahi, ufw firewall, cups-pdf.
- Massive hardware-fix layer (the `install/config/hardware/` tree): vendor-specific fixes for ASUS, Framework, Apple T2, Lenovo, Surface, Intel IPU7 cameras, thermald/lpmd, Wi-Fi regdom, bluetooth autosuspend — *this is the unglamorous bulk of what makes it a daily driver.*

**Excludes (notable):** no Firefox, no GNOME/KDE apps beyond the handful above, **no flatpak/snap**, no TLP/tuned (just ppd), no X11 session, no greeter bloat (sddm, minimal theme), no office-suite alternatives beyond LO, no games/launchers, no email client, no system-settings GUI — everything configured via dotfiles/TUI. Also no clipboard persistence manager and no notification center beyond mako — both frequently criticized gaps.

**Praise/criticism patterns** (from community discourse): praised for coherent theming, working-out-of-box hardware (especially laptops), and opinionated keybindings. Criticized for: DHH-opinionated choices being hard to override (config files get force-overwritten on update — the biggest structural complaint), Chromium-only browser, missing clipboard history by default, update breakage inherent to Arch rolling, and the `omarchy` update scripts replacing user dotfiles. **Lesson for Callisto: the #1 design decision is the user-config vs distro-config boundary.** Omarchy's pain is our warning — separate `/usr/share/callisto/` defaults from `~/.config` user overrides with a documented merge/priority scheme from day one.

---

## 9. Bloat traps and silent killers

### Bloat traps (ship-avoid)
- **Two of anything in one category**: NM + systemd-networkd enabled simultaneously; ppd + TLP; hypridle + swayidle; mako + dunst; multiple portals for same interface.
- **Desktop-environment hangers-on**: gnome-control-center pulls gnome-settings-daemon pulls half of GNOME; kde "systemsettings" likewise. Avoid both — write shell-native settings or do without.
- **Tracker/MinerFS indexing daemons**, baloo — heavy background indexing nobody asked for. `plocate` (Omarchy's choice) gives search at zero runtime cost.
- **Evolution/Geary/email+calendar suites**, games, help/documentation viewers (`yelp` + the doc corpus), backup utilities (DejaDup), parental-controls/malware-scanner GUIs.
- **Snapd** (obviously), and flatpak *with preinstalled apps*.
- **Bluetooth-cum-GUI bloat**: blueman is fine but superseded by shell-native.
- **PackageKit** daemon unless you ship a GUI store.
- Multiple terminals/editors/browsers. One of each, chosen.
- `xscreensaver`-era stuff, xdg-screensaver hacks, `redshift` (X11-only!).
- **cups vendor driver piles** (hplip full, gutenprint giant sets) — driverless first, install on demand.

### Silent killers (omissions that make desktop life painful — all cheap to include)
- **Missing MIME handler associations** → "nothing happens when I click a file." Omarchy has a dedicated `mimetypes.sh` config step. Ship `xdg-utils` + a curated `mimeapps.list`.
- **No thumbnailers** → file manager feels broken. `ffmpegthumbnailer` + tumbler or nautilus's internal ones; ensure the thumbnailer D-Bus services resolve.
- **No trash support** → gvfs is required (`gvfs`, `gvfs-backends`); without it delete = permanent. GVFS also provides trash:///, mtp, smb browsing.
- **No xdg-user-dirs** → home fills with lowercase literal dirs or none at all; first-run `xdg-user-dirs-update` (Omarchy: `user-dirs.sh`).
- **Missing fonts**: without `fonts-noto`, CJK and emoji every web page is tofu boxes. Font package set is heavy but mandatory: `fonts-noto`, `fonts-noto-cjk`, `fonts-noto-color-emoji` + one good monospace nerd font.
- **No `pipewire-pulse`** → half the Linux audio guides and apps silently break.
- **Missing `polkit` agent autostart** → every privileged GUI action silently fails. #1 most common broken-Hyprland-install symptom on reddit.
- **No portal** → screensharing on Wayland silently black-screens in Zoom/Discord/Chrome. Portal config must name the right backend or nothing works and nothing errors visibly.
- **Missing ntfs/exfat/sshfs filesystem support** (`exfatprogs`, `ntfs-3g`, `sshfs`) — tiny packages, huge "Linux can't read my drive" factor.
- **Time sync / timezone**: `systemd-timesyncd` on; Omarchy even ships `tzupdate` for geo-tz. NTP being off breaks TLS in weird ways.
- **Firmware**: on Debian this means enabling `non-free-firmware` and shipping `firmware-linux`, `firmware-iwlwifi`, `firmware-realtek`, `firmware-amd-graphics`, sof audio firmware (`firmware-sof-signed`). Skipping this is the classic Debian-derivative death: installer works, installed system has no Wi-Fi.
- **SSE**: speech-dispatcher, orca — accessibility stack. Cheap, and its absence is both exclusionary and sometimes a hard dependency of toolkit a11y buses.
- **Caps-lock/compose and keymap propagation** to the Wayland session; XCompose support (Omarchy configures it).

---

## 10. Debian trixie package reference per subsystem

All of the following returned HTTP 200 at packages.debian.org/trixie today (verified programmatically):

- **Power:** `power-profiles-daemon`, `upower`, `thermald`, `tuned-ppd` (if ever), `powertop` (diagnostic only)
- **Session:** `hyprland`, `hypridle`, `hyprlock`, `hyprsunset`, `hyprpolkitagent`, `uwsm`, `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `gnome-keyring`, `libsecret-1-0`/`libsecret-tools`, `polkitd`, `greetd`, `swayosd`, `mako`, `wl-clipboard`, `wl-clip-persist`, `cliphist`, `grim`, `slurp`, `satty`, `hyprpaper`, `waybar`, `quickshell`
- **Audio/BT:** `pipewire`, `pipewire-audio`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber`, `wiremix`, `bluez`, `bluetui`, `libspa-0.2-bluetooth` (+ check `libspa-0.2-codec-bluez5`), `playerctl`, `mpv`
- **Network:** `network-manager`, `iwd`, `impala`, `network-manager-applet` (fallback), `avahi-daemon`, `libnss-mdns`, `wireless-regdb`, `ufw`
- **Input/display:** `brightnessctl`, `gammastep` (unused backup), `libinput-gestures` (optional), `fcitx5`, `fcitx5-gtk`, `fcitx5-qt`, `xwayland`, `xdg-utils`, `xdg-user-dirs`
- **Print:** `cups`, `cups-browsed`, `cups-filters`, `cups-pdf`, `ipp-usb`, `system-config-printer`
- **FS/IO quality-of-life:** `gvfs`, `gvfs-backends`, `ffmpegthumbnailer`, `exfatprogs`, `ntfs-3g`, `sshfs`, `plocate`
- **Firmware:** `firmware-linux`, `firmware-iwlwifi`, `firmware-realtek`, `firmware-sof-signed` (require non-free-firmware enabled)
- **Fonts:** `fonts-noto`, `fonts-noto-cjk`, `fonts-noto-color-emoji`

## Prioritized master table

| Subsystem/component | Priority | Rationale |
|---|---|---|
| power-profiles-daemon (never TLP/tuned alongside) | **essential-now** | the power API everything expects |
| UPower, logind lid/power config | **essential-now** | battery + lid correctness on day one |
| uwsm session management | **essential-now** | correct systemd-user/env semantics; everything downstream depends |
| xdg-desktop-portal + hyprland backend + gtk fallback, correctly configured | **essential-now** | screenshare/screenshot silently broken otherwise |
| exactly one polkit agent autostarting (hyprpolkitagent) | **essential-now** | silent failure is the #1 Hyprland complaint |
| pipewire-audio + wireplumber + pipewire-pulse | **essential-now** | audio |
| NetworkManager (+iwd backend) | **essential-now** | network |
| hypridle + hyprlock (ext-session-lock) | **essential-now** | security baseline |
| non-free firmware set incl. iwlwifi/realtek/sof | **essential-now** | hardware actually working |
| fonts-noto incl. CJK+emoji | **essential-now** | web unreadable otherwise |
| gnome-keyring + PAM integration | **essential-now** | browser password stores etc. |
| wl-clip-persist | **essential-now** | famous papercut, trivially cheap |
| swayosd + brightnessctl + input/video group setup | **essential-now** | working fn-keys are the visible quality signal |
| gvfs + backends (trash, mtp, smb) + ffmpegthumbnailer + MIME defaults + xdg-user-dirs | **essential-now** | the silent-killer cluster |
| mako or shell-native notifications | **essential-now** | apps expect a notification daemon |
| grim/slurp/satty + gpu screen recording path | **essential-now** | core desktop verbs |
| hyprsunset | **essential-soon** | night light is expected but not day-one critical |
| cups + cups-pdf + ipp-usb + cups-browsed | **essential-soon** | include, per Omarchy/Fedora evidence; driverless-first config |
| bluetoothd + libspa-0.2-bluetooth + codec package + bluetui/shell UI | **essential-soon** | verify codec split in Debian; BT audio must not be SBC-only |
| fcitx5 input method stack | **essential-soon** | CJK users are a hard requirement for a "real OS" |
| thermald (Intel) + hardware-fix script layer | **essential-soon** | Omarchy's hidden moat — start small, grow per-device |
| clipboard history (cliphist) | **essential-soon** | expected in 2026 desktop UX |
| Quickshell-native network/bt/power/notification center replacing TUIs/mako/nm-applet | **essential-soon** | the actual product differentiator |
| flatpak installed but empty (Flathub configured) | **optional** | escape hatch for Debian staleness; no preinstalled flatpaks |
| obs-studio, kdenlive, LibreOffice | **optional** | decide by ISO size budget; Omarchy includes, Fedora includes LO |
| ufw (inactive), modemmanager, libinput-gestures | **optional** | situational |
| TLP, tuned-ppd, auto-cpufreq (concurrent) | **avoid** | conflicting power writers |
| gnome-control-center / KDE systemsettings + their daemon trains | **avoid** | DE infrastructure gravity |
| tracker/miner/baloo indexing daemons | **avoid** | background cost, no shell integration |
| snapd, preinstalled flatpaks | **avoid** | philosophical + weight |
| xscreensaver/redshift/X11-era display hacks | **avoid** | wrong display server |
| email clients, games, yelp help viewers, backup suites | **avoid** | classic ISO-padding bloat |
| multiple items per category (mako+dunst, networkd+NM, etc.) | **avoid** | the definition of bloat |

## Open uncertainties flagged

1. **Fedora post-F41 tuned status** — I confirmed the F41 change making tuned-ppd default, but could not confirm whether later Fedoras (42/43) reverted to ppd after user-reported regressions (there were credible reports of battery-life regressions with tuned). Doesn't change our recommendation (ppd).
2. **`libspa-0.2-codec-bluez5` in trixie** — the high-quality BT codec package; licensing historically kept it out of main. Needs verification whether it's in main/non-free or must be dropped/accepted as SBC+AAC-only.
3. **`gpu-screen-recorder` in trixie** — didn't verify; fallback is `wf-recorder` + portal capture.
4. **Hyprland version currency in trixie** — trixie froze mid-2025; hyprland there will age. Whether Callisto needs a backports/overlay repo from day one depends on what Quickshell features require. Investigate the exact trixie hyprland version vs. Quickshell's requirements early — this is the biggest technical-risk item in the whole stack.
5. **Omarchy moving parts** — Omarchy master currently uses `polkit-gnome` not `hyprpolkitagent`, uses waybar not a custom shell, and doesn't ship wl-clip-persist/cliphist despite user requests; I've recommended the better alternatives deliberately rather than copying blindly.
6. **pmOS/Sway-spin specifics** — I relied on general knowledge for their composition rather than fetching their exact package lists in the time available; their user-facing stack conclusions (pipewire+wireplumber+NM+iwd+ppd) are uncontroversial and corroborated by Omarchy/Fedora regardless.
