# Research: production-grade Debian live ISO engineering with `live-build` (Debian 13 "trixie")

Compiled 2026-11-26 for the Callisto project (Hyprland live ISO on trixie). All facts
sourced from primary materials: the live-build source tree on salsa.debian.org, the
Debian Live Manual, the Kali `kali-live` build scripts, and Debian archive metadata
(`dak ls` via qa.debian.org). Uncertainties are flagged inline as **[UNCERTAIN]**.

---

## 0. Headline answer: hyprland and quickshell ARE packaged for trixie — but ONLY in trixie-backports

From `dak ls` (the authoritative Debian archive listing, via qa.debian.org/madison.php) [1][2]:

```
hyprland   | 0.55.2+ds-1~bpo13+1 | trixie-backports | source, amd64, arm64, armel, armhf, i386, ppc64el, riscv64, s390x
hyprland   | 0.57.0+ds-1         | forky            | (testing)
hyprland   | 0.57.2+ds-1         | sid              | (unstable)

quickshell | 0.3.0-1~bpo13+1     | trixie-backports | source, amd64, arm64, armel, armhf, i386, ppc64el, riscv64, s390x
quickshell | 0.3.2-1             | forky            |
quickshell | 0.3.2-1             | sid              |
```

Implications, critically important for the plan:

- **Neither package exists in trixie proper (main).** They were packaged after the trixie
  freeze and exist for trixie users **only via the `trixie-backports` suite**.
- Exact binary package names on amd64: **`hyprland` 0.55.2+ds-1~bpo13+1** and
  **`quickshell` 0.3.0-1~bpo13+1**.
- Therefore `--backports true` (or an explicit `config/archives/trixie-backports.list.chroot`)
  is **mandatory** for Callisto. Because backports carry pin-priority 100 (NotAutomatic),
  plain `apt install hyprland` inside the chroot **does** resolve to the backport version
  when the package does not exist in trixie at all — apt picks the highest-installable
  candidate across suites. However, dependencies of hyprland that *do* exist in trixie
  (older versions) will NOT automatically be upgraded to backports versions. If hyprland's
  deps require backported versions, they must be pinned or the whole suite pinned higher
  (see §1.4). **[verify the dependency chain of hyprland 0.55.2 — e.g. libhyprutils,
  aquamarine, hyprland-protocols — all of which are also only in backports; check at build time]**
- Note the versions are slightly dated relative to upstream (Hyprland 0.55.2 vs 0.5x current,
  quickshell 0.3.0 vs 0.3.2). Anything in Callisto that depends on newer upstream features
  will not be satisfiable from the Debian archive.

---

## 1. `lb config` options as used by production projects

### 1.1 Debian's own live images (salsa: live-team/live-images, branch `debian`) [3]

Per-flavour trees under `images/{gnome,kde,xfce,cinnamon,lxde,mate,standard}-desktop/` with an
`auto/config` that is intentionally minimal:

```sh
lb config noauto \
    --clean \
    --ignore-system-defaults \
    --mode debian \
    --debian-installer live \
    --linux-packages "linux-image linux-headers" \
    --source "${_SOURCE}" \
    "${@}"
```

Key observations:
- They rely on live-build defaults for almost everything; the distro knowledge lives in the
  `config/` tree (package lists, bootloader configs, hooks).
- `--ignore-system-defaults` is used so the build hermeticity doesn't depend on the host's
  `/etc/live/build.conf` — worth copying.
- `--debian-installer live` includes the **live-installer** udeb: the installer copies the
  live squashfs to disk instead of installing .debs one by one. This is how the official
  Debian live images offer a working installer on the boot menu.
- `--linux-packages "linux-image linux-headers"` pulls kernel headers too (they ship DKMS
  modules: see `dkms.list.chroot_live` with open-vm-tools/virtualbox guest packages) [3].

Their package lists (`images/gnome-desktop/config/package-lists/`) are small and modular [3]:
- `desktop.list.chroot` → `task-gnome-desktop`, `task-print-server`, `plymouth`, `plymouth-x11`,
  `gstreamer1.0-vaapi`, `i965-va-driver`
- `standard.list.chroot` → `! Packages Priority standard` (generated list via the `Packages`
  helper), `task-laptop`, `task-ssh-server`
- `installer.list.chroot` → `debian-installer-launcher` (the desktop "Install Debian" icon)
- `dkms.list.chroot_live` / `dkms.list.chroot_install` → guest-agent packages, with conditional
  blocks `#if PARENT_ARCHIVE_AREAS contrib ... #endif`
- `live-systems.list.chroot` → `live-manual`, `live-tools`
- one hook only: `0001-plymouth-theme.hook.chroot` runs `plymouth-set-default-theme lines`.

They also vendor entire **syslinux/isolinux/pxelinux/extlinux** trees into
`config/bootloaders/` (including `live.cfg.in` templates and the splash) rather than accepting
live-build's stock menu — this is how they control the boot menu branding [3].

### 1.2 Kali Linux (gitlab.com/kalilinux/build-scripts/kali-live) [4][5]

Kali's `auto/config` is a fat shell script that resolves the release codename from the mirror,
then calls:

```
lb config noauto \
  --apt-indices=false \
  --distribution "$dist" \
  --debian-installer-distribution "$dist" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debootstrap-options "--keyring=/usr/share/keyrings/kali-archive-keyring.gpg" \
  --keyring-packages kali-archive-keyring \
  --updates false \
  --backports false \
  --source false \
  --firmware-binary true \
  --firmware-chroot true \
  --mirror-bootstrap "$kali_mirror" \
  --mirror-debian-installer "$kali_mirror" \
  --mirror-binary "$public_kali_mirror" \
  --iso-application "Kali Linux" \
  --iso-publisher "Kali" \
  --iso-volume "Kali Live" \
  --linux-packages linux-image \
  --memtest memtest86+ \
  --bootappend-live "boot=live components quiet splash noeject" \
  --bootappend-live-failsafe "boot=live components noeject memtest noapic noapm nodma nomce nolapic nomodeset nosmp nosplash vga=normal" \
  --bootappend-install "net.ifnames=0" \
  --security false \
  --win32-loader false \
  $lb_opts "$@"
```

with per-arch extras: amd64/i386 get `--debian-installer live`; arm64 gets
`--bootloaders grub-efi --uefi-secure-boot disable`; armhf builds an `hdd` image instead.

What matters for Callisto:
- **`--bootappend-live "boot=live components quiet splash noeject"`** — note the explicit
  `boot=live components`. If you write your own `--bootappend-live` string and omit these,
  live-boot/live-config may not fully initialize. **[The exact minimal required set is
  version-dependent; copying this Kali string verbatim is the safe baseline.]**
- `--apt-indices=false` shrinks the image (no `/var/lib/apt/lists` on the live system);
  the tradeoff is users must `apt update` before installing anything [6].
- Mirror split: build-time mirror vs the public mirror embedded in the finished image
  (`--mirror-binary`). For Callisto on pure Debian this split is unnecessary; defaults
  (`deb.debian.org`) are fine.
- Kali needs the symlink hack `ln -sf sid /usr/share/live/build/data/debian-cd/kali-rolling`
  because live-build consults debian-cd's distro table. **Not needed when building a pure
  Debian trixie image** — `trixie` is a known codename [4].
- Kali disables `--updates`/`--security`/`--backports` because it's a rolling distro. For
  trixie, the Debian defaults (`--updates true --security true`) are correct; you want
  `--backports true` explicitly (see §0).

### 1.3 Defaults that are wrong or need attention for a desktop live ISO

From lb_config(1) (trixie live-build 1:20250505+deb13u1) [7]:

- `--distribution` defaults to **testing** — must set `trixie` explicitly.
- `--archive-areas` defaults to **main only** — a desktop ISO realistically needs
  `"main contrib non-free non-free-firmware"` or users get no wifi/GPU firmware.
  Note `--firmware-chroot true` is default but does nothing unless the non-free-firmware
  area is enabled [7].
- `--binary-image` defaults to `iso-hybrid` when syslinux is in use — this is what you want
  (ISO bootable both from CD emulation and when dd'ed to USB).
- Bootloaders: on amd64 the automatic default is already BIOS=syslinux(isolinux) +
  EFI=grub-efi (see §4.2) — both BIOS and UEFI boot are covered without extra flags.
- `--debian-installer` defaults to `none` — decide consciously (§4.3).
- `--chroot-squashfs-compression-type` defaults to `xz` (§4.4).
- `--apt-recommends` defaults to true; Kali and Debian keep it. If you turn it off you must
  re-add `user-setup` and `sudo` or the live user is never created and cannot gain root [6].
- `--backports` defaults to **false** (`LB_BACKPORTS="${LB_BACKPORTS:-false}"` in
  `functions/configuration.sh` line 102) [8].

### 1.4 How `--backports true` interacts with apt pinning

`--backports true` only causes `functions/sourcelist.sh` to append [8]:

```
deb     ${MIRROR} ${DISTRIBUTION}-backports ${ARCHIVE_AREAS}
deb-src ${MIRROR} ${DISTRIBUTION}-backports ${ARCHIVE_AREAS}
```

to the chroot (and binary) sources lists — for any distribution except sid/unstable.
It does **not** write any apt preferences. The resulting behavior is plain Debian backports
semantics:

- The backports Release files carry `NotAutomatic: yes`/`ButAutomaticUpgrades: yes`, so apt
  assigns them priority **100** versus **500** for trixie. Versions already installed from
  trixie are never auto-upgraded to backports versions.
- A package that exists **only** in backports (hyprland, quickshell) installs fine from
  priority 100 — pinning is not needed for the top-level package.
- But any dependency of those packages that exists in *both* suites will be taken from
  trixie even if the backport version is required. If `apt` resolution fails or picks wrong
  versions, the documented live-build mechanism is pinning snippets:
  `config/archives/<name>.pref.chroot` (build-time) and/or
  `config/includes.chroot/etc/apt/preferences.d/...` (runtime) [6]. Example for forcing
  backports preference for a set of packages:

  ```
  Package: hyprland quickshell libhyprutils* aquamarine hyprland-protocols hyprwayland-scanner xdg-desktop-portal-hyprland
  Pin: release n=trixie-backports
  Pin-Priority: 990
  ```

  **[UNCERTAIN: exact list of hyprland dependency package names — resolve with
  `apt-cache depends hyprland` inside a trixie-backports environment before committing.]**

---

## 2. `includes.chroot/` vs `hooks/live/*.hook.chroot` vs `package-lists/*.list.chroot`

Per the Debian Live Manual ch. 8–9 [6][9] and observed usage:

| mechanism | what it is | when production projects use it |
|---|---|---|
| `config/package-lists/*.list.chroot` | newline-separated package names installed by apt during the chroot stage. Supports `#if VAR value` / `#endif` conditionals over lb-config variables and `! Packages Priority standard`-style generated lists [6]. | The primary vehicle for content. Both Debian and Kali split them by topic (`desktop`, `standard`, `hardware-support`, `firmware`...). The `.chroot` suffix means "installed in the live filesystem only"; the rarer `.list.chroot_live`/`.list.chroot_install` pair controls what the *live installer* strips out after copying the system to disk [6]. |
| `config/includes.chroot/` | a verbatim file tree overlaid onto the chroot **after package installation** (so it can overwrite package-shipped files) [9]. | Static config that doesn't need computation: `/etc/skel` dotfiles, `/etc/live/config.conf.d/*.conf` (live-config variables), systemd unit drop-ins, lightdm/sddm configs, polkit rules. Kali uses it for `etc/live/config.conf.d/kali.conf` and boot-time hook scripts in `usr/lib/live/config/` [4]. Debian uses it minimally because of the project's "no package configuration" philosophy [10]. |
| `config/hooks/live/*.hook.chroot` | executable shell scripts run **inside the chroot** near the end of the chroot stage (the `live/` subdirectory is for live images; `normal/` for non-live) [9]. Older files named `*.chroot` still work (Kali still uses `hooks/live/kali-hacks.chroot`) [4]. | Anything requiring execution: running `plymouth-set-default-theme`, `systemctl enable`-style symlinks, `update-alternatives`, gsettings/dconf compilation, cache regeneration, deleting files packages insist on installing. Ordering is controlled by numeric prefixes (`0001-...`). |
| `config/hooks/live/*.hook.binary` | run on the host (not chroot) at binary stage, before checksums — for modifying the ISO9660 tree itself [9]. | Rarely needed; e.g. dropping extra files onto the ISO root (though `config/includes.binary/` covers the static case). |

Rule of thumb matching production practice: **package-lists for what, includes for static
files, hooks for computation**. Never use hooks to do what includes can do statically
(less reproducible, harder to debug); never use includes to do what packages can do
(overwritten files create upgrade conflicts you can't see).

---

## 3. Config tree structure in production projects

**Debian** (live-team/live-images, branch `debian`) [3]:

```
images/gnome-desktop/
├── auto/config              # tiny lb config wrapper (§1.1)
├── config/
│   ├── bootloaders/{extlinux,isolinux,pxelinux,syslinux}/   # full vendored boot menu trees incl. live.cfg.in
│   ├── hooks/0001-plymouth-theme.hook.chroot
│   └── package-lists/
│       ├── desktop.list.chroot
│       ├── dkms.list.chroot_install / dkms.list.chroot_live
│       ├── installer.list.chroot
│       ├── live-systems.list.chroot
│       ├── localization.list.chroot
│       ├── memtest.list.chroot
│       └── standard.list.chroot
```

**Kali** (build-scripts/kali-live) [4][5]:

```
build.sh, build-in-container.sh, Dockerfile
auto/config                     # big lb config wrapper (§1.2)
kali-config/
├── common/
│   ├── bootloaders/
│   ├── hooks/live/kali-hacks.chroot
│   ├── includes.binary/
│   ├── includes.chroot/
│   │   ├── etc/live/config.conf.d/kali.conf          # LIVE_HOSTNAME/USERNAME/FULLNAME
│   │   ├── etc/mysql/mariadb.conf.d/90-live.cnf
│   │   └── usr/lib/live/config/0031-kali-user-setup  # boot-time hook
│   ├── includes.installer/
│   ├── package-lists/{standard,hardware-support,linux-headers,virtualization}.list.chroot (+kali.list.binary)
│   └── preseed/
└── variant-{default,xfce,gnome,kde,mate,i3,lxde,e17,...}/   # per-desktop package lists + includes
```

`auto/config` copies `kali-config/common` plus one `variant-*` over `config/` before invoking
`lb config` — the "variants" pattern is worth copying if Callisto ever grows flavors [4].

**Parrot OS**: their build system is not publicly mirrored on gitlab.com/salsa in a
readily-fetchable form (repos live behind their own GitLab); no first-hand config tree
could be retrieved. **[UNCERTAIN — omitted rather than guessed.]**

### Greeter autologin for live sessions

This is **not** done by the projects in their live-build config — it's done by
**live-config at boot time**. live-config ships per-display-manager components [11]:

- `0080-gdm3` writes `AutomaticLoginEnable=true`, `AutomaticLogin=<live user>`,
  `TimedLogin*` into `/etc/gdm3/daemon.conf`
- `0085-sddm`, `0100-lightdm`, `0110-lxdm`, `0120-nodm`, `0130-slim`, `0140-xinit` do the
  equivalent for their DM — sddm and lightdm included
- `0030-user-setup` creates the live user (default `user`, password `live`)

The username/hostname are controlled via `includes.chroot/etc/live/config.conf.d/*.conf`
(Kali: `LIVE_USERNAME="kali"` etc.) or boot parameters (`username=`). Autologin can be
disabled with `noautologin`/`nox11autologin` boot params [11][12].

**For Callisto**: if the greeter is **sddm** or **lightdm**, autologin works out of the box
with zero config — just install the DM. If you want Hyprland to start without any greeter,
the live-config mechanism is `0140-xinit` + nodm, or a custom boot-time hook in
`config/includes.chroot/usr/lib/live/config/` (number-prefix ordered; Kali's
`0031-kali-user-setup` is the template) [9][4]. A greeterless autostart can alternatively
be done with a systemd unit or `/etc/skel` profile logic in the live user's session, but the
live-config path is the production-grade one because it composes with the live boot
parameters.

---

## 4. Known pitfalls

### 4.1 Building trixie live images inside a debian:trixie container

- Kali ships exactly this pattern (`build-in-container.sh` + `Dockerfile` installing
  `live-build` + `apt-utils`), proving it is viable — **but** the container must run
  **privileged** (or at minimum with `CAP_SYS_ADMIN` and the ability to bind-mount
  `/proc`, `/sys`, `/dev/pts` inside the chroot). live-build's chroot stage mounts these
  filesystems; in restricted container runtimes (default docker/podman seccomp+no-priv)
  the build fails obscurely. **[UNCERTAIN in detail: exact capability set depends on
  runtime; Kali documents needing `--privileged` for docker in practice. Verify against
  your container runner.]**
- Host/target parity matters because live-build uses *host* tools for the binary stage
  when versions match, and the man page warns explicitly: host xorriso/syslinux/grub/
  squashfs-tools must match the target distribution or images can be non-bootable —
  building in a `debian:trixie` container is therefore the *correct* choice (it satisfies
  `--build-with-chroot true`'s intent). Do not build on an unstable/forky host [7].
- debootstrap of trixie from inside a trixie container is a same-version bootstrap — the
  straightforward case, no qemu or cross-arch concerns for amd64→amd64.
- `lb config` must be run once, cleanly: re-running it over an existing config silently
  keeps stale auto-derived values. Use `auto/config` with `noauto` + `lb clean` discipline
  like both production projects do [7].

### 4.2 ISO hybrid boot: isolinux + grub-efi

- In current live-build, bootloaders are split into `LB_BOOTLOADER_BIOS` (default
  `syslinux` on amd64/i386 for iso images) and `LB_BOOTLOADER_EFI` (default `grub-efi`)
  [8]. So **bios isolinux + UEFI grub-efi is the automatic default**; passing
  `--bootloaders "syslinux grub-efi"` merely makes it explicit.
- The ISO is assembled by xorriso with `-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin
  -partition_offset 16` for the BIOS/isohybrid part, El Torito `-b isolinux/isolinux.bin`,
  and a separate EFI system partition image embedded for UEFI (`binary_grub-efi`/`efi-image`
  build the ESP with mtools+mkfs.msdos) [8]. Result: one ISO that boots under BIOS,
  UEFI, and when dd'ed raw to USB — the "isohybrid" layout.
- `--uefi-secure-boot auto` (default) installs signed shim+grub **if available**. In Debian
  they are (`shim-signed`, `grub-efi-amd64-signed`), so a trixie build gets Secure Boot
  support for free. Note Kali can't use them (no signed packages in their archive) and
  patches live-build's xorriso EFI options for Mac/UEFI quirks — evidence that the stock
  Debian xorriso invocation has had edge-case trouble on some firmware (Macs especially).
  **[UNCERTAIN whether the 2025 live-build fixes fully cover Mac booting; mostly irrelevant
  unless Mac hardware is a target.]** [5]
- The Debian images project **vendors** the entire `config/bootloaders/isolinux` + `syslinux`
  trees (menu cfg, `live.cfg.in`, splash) to control branding — copy this approach if
  Callisto needs a custom boot menu, but note the templates use `@VARIABLE@` substitutions
  performed by live-build [3].

### 4.3 What `--debian-installer none` implies

- `none` is the **default** [7]. The ISO boots to the live system only; there is no
  installer boot menu entry, no `debian-installer-launcher` desktop icon, no d-i images
  fetched (saves build time and several hundred MB).
- `live` (what Debian and Kali use) embeds the debian-installer plus the **live-installer**
  udeb: the installer copies the live squashfs contents to the target disk — fast installs,
  and exactly "what you tried is what you get". It requires `--debian-installer-distribution`
  to match and pulls in the `.list.chroot_live`/`.list.chroot_install` removal machinery [6][7].
- `cdrom`/`netinst` etc. are the classic package-installing d-i flavors.
- For Callisto: if installation to disk is not a goal, `none` is correct and simplest.
  If it is, follow Debian's pattern (`--debian-installer live` + `debian-installer-launcher`
  in a package list) — but be aware trixie's d-i for trixie must be fetchable, which pins
  your build to the archive layout of the release.

### 4.4 Squashfs compression: xz vs zstd

- Default is **xz** (hardcoded fallback `-comp xz` in `scripts/build/binary_rootfs`) [8].
  Override with `--chroot-squashfs-compression-type zstd` and optionally
  `--chroot-squashfs-compression-level`.
- Tradeoffs (well-established squashfs facts; exact numbers depend on content and hardware —
  **[UNCERTAIN: no live-build-specific benchmark is published; treat ratios as typical
  squashfs values]**):
  - **xz**: smallest image (typically 20–30% smaller than zstd at default levels), very slow
    compression at build time, slow decompression at boot/runtime — every file read from the
    squashfs is decompressed on demand, so xz directly affects boot time and application
    startup on the live system.
  - **zstd**: meaningfully larger image but much faster decompression (~an order of magnitude)
    and fast compression; at high levels (`-Xcompression-level 19`, or zstd 22 with recent
    squashfs-tools) it approaches xz sizes while keeping fast decompression. This is what
    Fedora (zstd) and most modern live distros converged on.
  - Kernel support for zstd squashfs is present in all trixie kernels — no compatibility risk.
- For a desktop live ISO where boot speed and snappy cold-start matter, **zstd is the
  defensible default**; xz if minimizing download size dominates. Benchmark both on real
  hardware before release.

---

## 5. Additional flag-level facts worth pinning down in Callisto's auto/config

A reasonable baseline distilled from the above (not a deliverable, just the research summary):

```
lb config noauto \
  --ignore-system-defaults \
  --mode debian \
  --distribution trixie \
  --debian-installer none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --backports true \
  --security true \
  --updates true \
  --firmware-chroot true \
  --firmware-binary true \
  --bootloaders "syslinux grub-efi" \
  --binary-image iso-hybrid \
  --bootappend-live "boot=live components quiet splash" \
  --chroot-squashfs-compression-type zstd \
  --linux-packages linux-image \
  --iso-application "Callisto" ...
```

(plus the backports pinning snippet from §1.4 in `config/archives/` if dependency
resolution misbehaves).

---

## Sources

1. qa.debian.org `dak ls` for `hyprland`: https://qa.debian.org/madison.php?package=hyprland&table=debian (retrieved 2026-11-26)
2. qa.debian.org `dak ls` for `quickshell`: https://qa.debian.org/madison.php?package=quickshell&table=debian (retrieved 2026-11-26)
3. Debian live images config trees: https://salsa.debian.org/live-team/live-images (`debian` branch, `images/gnome-desktop/`, retrieved via GitLab API 2026-11-26)
4. Kali live build scripts: https://gitlab.com/kalilinux/build-scripts/kali-live (`auto/config`, `kali-config/`, retrieved via GitLab API 2026-11-26)
5. Kali live-build packaging changelog (xorriso EFI notes): https://gitlab.com/kalilinux/packages/live-build/blob/kali/master/debian/changelog
6. Debian Live Manual, ch. 8 "Customizing package installation": https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-package-installation.en.html
7. `lb_config(1)` man page, live-build 1:20250505+deb13u1 (trixie): https://manpages.debian.org/trixie/live-build/lb_config.1.en.html
8. live-build source tree: https://salsa.debian.org/live-team/live-build (`master` branch: `functions/sourcelist.sh`, `functions/configuration.sh`, `scripts/build/binary_rootfs`, `scripts/build/binary_iso`, retrieved 2026-11-26)
9. Debian Live Manual, ch. 9 "Customizing contents": https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-contents.en.html
10. Debian Live Manual, ch. 2 project philosophy: https://live-team.pages.debian.net/live-manual/html/live-manual/about-project.en.html
11. live-config source tree: https://salsa.debian.org/live-team/live-config (`components/0080-gdm3`, `0085-sddm`, `0100-lightdm`, `0120-nodm`, `0140-xinit`, `0030-user-setup`, retrieved 2026-11-26)
12. Debian Live Manual, ch. 10 "Customizing run time behaviours": https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-run-time-behaviours.en.html

*Note: packages.debian.org and salsa.debian.org HTML pages are behind anti-bot challenges;
Debian facts were therefore verified through qa.debian.org's madison interface and the
respective GitLab REST APIs, which serve the same authoritative data.*
