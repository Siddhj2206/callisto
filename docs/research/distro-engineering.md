# Distro Engineering Research for Callisto

Research notes on how production Linux distributions structure ISO build repos, containerized
live-build, reproducibility, QEMU testing, and derivative branding. Compiled 2026-11-26 for
bootstrapping Callisto, a Debian 13 (trixie) live ISO with a custom Hyprland desktop.

---

## 1. Repository layout conventions in production ISO projects

### Kali Linux — `kalilinux/build-scripts/kali-live` (the best reference for live-build)

The closest structural analog to Callisto. Flat repo, shell-script entrypoints, live-build
config tree kept in-repo:

```
.
├── build.sh                  # main entrypoint: arg parsing, validation, lb config + lb build
├── build-in-container.sh     # wrapper: detects docker/podman, builds+runs helper container
├── Dockerfile                # build-helper container (live-build, apt-utils, ...)
├── auto/                     # live-build's own config/clean/build hook scripts
├── kali-config/
│   ├── common/               # shared: hooks/, includes.chroot/, includes.binary/
│   ├── variant-default/      # one dir per desktop/edition variant
│   ├── variant-gnome/
│   └── ...                   # each has package-lists/<x>.list.chroot
├── .gitlab-ci.yml            # lint (shellcheck/yamllint/hadolint) + container build/push
├── LICENSE                   # GPL-2.0
└── README.md
```

Notable conventions:

- **CLI-over-env-var parametrization**: every flag `--arch/-a`, `--branch/-b`, `--variant/-v`,
  `--version/-x`, `--mirror/-m`, `--hostname/-H`, `--output/-o`, `--keep/-k` can be preset by an
  upper-cased environment variable (`ARCH`, `BRANCH`, `VARIANT`, ...). Mirrors are parameterized,
  and apt caching proxies (`localhost:3142` apt-cacher-ng, `localhost:8000` squid-deb-proxy) are
  auto-detected. [1]
- **Naming scheme**: `kali-linux-$VERSION-live[-$VARIANT]-$ARCH.iso` composed in a shell function
  (`target_image_name`). Version defaults to the branch name minus the `kali-` prefix; artifacts go
  to an `images/` or `output/` dir, with a sibling `.log` file per image. [2]
- **Validation upfront**: checks variant dir exists, checks minimum `live-build` version with
  `dpkg --compare-versions` before doing any work, refuses cross-arch builds it can't do
  (needs qemu-user-binfmt for cross-arch).
- **No Makefile** — Kali uses shell scripts, not make. The `lb` tool itself reads `auto/config`.
- **CI**: lint stage first (shellcheck/yamllint/hadolint), then build/push the helper container.
  Heavy ISO builds are not in the default CI path.
- Kali split installer images (simple-cdd/debian-cd based) into a separate repo `kali-installer`;
  live images stay live-build based. The split happened around 2025. [1]

### Debian's own live-images — `live-team/live-build` + `live-images` on salsa.debian.org

Debian's official live images are built with live-build configs maintained by the live team, but
the **reproducible rebuild infrastructure** is the interesting part (see §3). Roland Clobus's
rebuild scripts pin: git commit of live-build config, `SOURCE_DATE_EPOCH` derived from the archive's
`InRelease` timestamp, snapshot.debian.org mirror URLs, and the exact `lb config` command line —
these four things are the reproducibility contract. [7][8]

### Fedora — kickstarts + lorax/livemedia-creator (different world)

Fedora uses flat kickstart repos (`fedora-kickstarts` on pagure): one `.ks` per spin, `%.ks`
includes (`%include`) shared base files, built with `livemedia-creator` (lorax) inside mock or
a VM. Composes are driven by `pungi` with XML/JSON compose configs in `pungi-fedora`. Parametrization
is by release version macro substitution, and official composes run on dedicated compose hosts,
not containers. Relevant mainly as a contrast: Debian-derivative ISO work is live-build-shaped,
not lorax-shaped.

### Ubuntu — `livecd-rootfs`

A single source package with per-series branches. Builds run as **hooks inside Ubuntu's
Launchpad/livefs build farm** — `livecd-rootfs` is a collection of shell hook functions
(`auto/config` equivalents) plus per-flavor layers in `live-build/ubuntu*/` subtrees. Not
containerized; depends on a real Ubuntu host with loop devices. Again a contrast: you only copy
this if you have a build farm.

### Parrot OS — `parrot-tools` / live-build configs

Parrot follows the same shape as Kali (they forked the Kali live-build-config approach): flat repo,
`build.sh`, `auto/`, config tree with per-variant dirs, templates for includes and package lists.
(Flagged uncertainty: Parrot's build repo is less documented publicly than Kali's; treat Kali as
canonical.)

### Common denominators worth copying

1. One entrypoint script (`build.sh`) with getopt CLI + env-var fallback, not a pile of make targets.
2. Live-build config tree versioned in-repo (`config/` or `<distro>-config/`), split into
   `common/` + `variant-*/` dirs; variants are dirs, not branches.
3. Package lists in `package-lists/*.list.chroot`, overlays in `includes.chroot/`, custom logic in
   `hooks/` — live-build's native vocabulary, nothing clever on top.
4. Container wrapper script separate from the builder script (`build-in-container.sh` wrapping
   `build.sh`), so the same script runs on host or in container.
5. Artifact naming as a pure function of (version, variant, arch); logs next to artifacts.
6. Lint shell scripts in CI even if you don't build ISOs in CI.

## 2. Containerized live-build: does `--privileged` docker/podman work for trixie?

Yes — this is exactly what Kali ships (`build-in-container.sh` + Dockerfile), and it's the
dominant pattern. But there are sharp edges, all documented:

**What must be true:**

- **Rootful engine.** live-build runs debootstrap, which does `mknod` for device nodes in the
  chroot. Rootless user namespaces forbid `mknod` even under `--privileged` — the build dies
  partway through the chroot stage. Docker Desktop is rootful by default; podman must be
  `podman machine set --rootful` or natively rootful. [9]
- **`--privileged` (or at minimum a careful cap set)**. Builds need loop devices, mounts,
  chroot. Known failure modes:
  - Docker's `/dev` is a tmpfs that does **not** auto-populate `/dev/loop*`; recent Docker versions
    tightened this further. Workaround: `mknod /dev/loop0..31` inside the build script before
    losetup. Podman `--privileged` bind-mounts host `/dev` and "just works". [10]
  - debootstrap inside `--privileged` can unmount the container's own `/proc` and break the
    container; workaround used in practice: non-privileged `--cap-add SYS_CHROOT --cap-add SYS_ADMIN
    --cap-add MKNOD` works for pure debootstrap, but loop-device image assembly then needs privilege
    anyway — most projects just accept `--privileged` with `-v /dev:/dev` and treat the build
    container as root-equivalent on the host. [11]
- **Don't bind-mount the source tree into the build on Windows/9P-style filesystems** — mount
  options (`nodev`) break mknod. Copy the tree in via the Dockerfile instead. Less relevant on a
  Linux host, but explains Kali's COPY-based Dockerfile. [9]
- squashfs/xorriso themselves are fine in containers (pure userspace); it's only the loop/mount
  and mknod steps that need privilege.

**The mmdebstrap alternative** (worth noting for Callisto even if you stay on live-build):

mmdebstrap is in trixie, uses apt for dependency resolution (vs debootstrap's internal resolver),
can run **unprivileged via user namespaces** (`--mode=unshare` — the default for non-root users),
writes output directly to tar or squashfs (`out.sqfs`), and is `SOURCE_DATE_EPOCH`-reproducible.
Debian's own tooling is migrating toward it. For a full live ISO with bootloader layout and hybrid
ISO generation, live-build is still the more complete tool; mmdebstrap is the better chroot/rootfs
builder underneath. Several newer projects (miniOS, various rescue systems) pair mmdebstrap-style
rootfs construction with manual xorriso assembly and never need `--privileged` or loop devices.
Live-build itself can use mmdebstrap as its bootstrap program in newer versions. [12]

**Recommendation for Callisto**: privileged-container live-build (Kali pattern) is proven and the
path of least resistance; pre-create `/dev/loop*` nodes inside the container entrypoint as insurance,
require rootful engine, and document the check `docker run --rm --privileged debian:trixie-slim
sh -c 'mknod /tmp/n b 7 99 && echo ok'` in the README.

## 3. Reproducibility practices for ISO builds

State of the art (Debian live images, Roland Clobus's work — now part of official practice):

- **Since March 2025, all major Debian desktop live images (bullseye/bookworm/trixie) rebuild
  bit-for-bit reproducibly from their binary packages** — no live-build patches required anymore;
  everything is upstream in live-build. [5][6]
- **The reproducibility contract is four inputs**: (1) git commit hash of the live-build config,
  (2) `SOURCE_DATE_EPOCH` — derived from the timestamp in the archive's `InRelease` file, not from
  the build clock, (3) the full `lb config` command line including snapshot.debian.org URLs pinned
  to a timestamp (`http://snapshot.debian.org/archive/debian/20200919T085932Z`), (4) additional
  package list. Debian embeds nothing magic in the ISO; the rebuilder reconstructs these. [7][8]
- **`SOURCE_DATE_EPOCH` must be exported before `lb config`, not just `lb build`** — the ISO volume
  ID timestamp is fixed at config time otherwise. Must also be after 1980-01-01 (EFI/FAT epoch).
  Suggested sourcing: `export SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)` for development builds,
  or the InRelease timestamp for pinned rebuilds. [8][13]
- **live-build handles the clamping**: with S_D_E set, all files on the image get timestamps
  truncated to it. Remaining known-diff files historically: `.disk/archive_trace`,
  `var/cache/apt/pkgcache.bin`, `var/cache/ldconfig/aux-cache` — mostly solved upstream now;
  verify with `diffoscope` between two builds. [8]
- **Rolling archives are the enemy**: a rebuild against a moving mirror won't reproduce. The answer
  is either snapshot.debian.org URLs (heavyweight but exact) or rebuilding within the same 6-hour
  DAK pulse. For Callisto: parametrize the mirror URL in `build.sh` exactly like Kali's `--mirror`,
  so snapshot URLs can be passed for reproducible release builds. [6]
- **Naming/versioning**: Debian live images are named
  `debian-live-<version>-<arch>-<flavor>.iso` (e.g. `debian-live-13.1.0-amd64-xfce.iso`); Kali is
  `kali-linux-<version>-live[-variant]-<arch>.iso`. Convention: lowercase, hyphen-separated,
  flavor last before arch. Version comes from a `--version` flag defaulting to something sensible,
  never from the wall clock baked into the filename (the wall-clock timestamps inside the image are
  what S_D_E handles).

## 4. QEMU testing of Wayland-compositor live ISOs

### Graphics device choices, in order of preference for Hyprland

1. **`virtio-vga-gl` (virglrenderer) with `-display gtk,gl=on`** — the current sweet spot.
   Gives the guest real GLES acceleration through the host GPU; Hyprland is unusable on pure
   llvmpipe for interactive testing (wlroots needs GLES; llvmpipe works but is painful).
   Canonical invocation assembled from QEMU docs + community practice:

   ```
   qemu-system-x86_64 \
     -enable-kvm -machine q35 -cpu host -smp 4 -m 4G \
     -object memory-backend-memfd,id=mem1,size=4G \
     -machine memory-backend=mem1 \
     -vga none -device virtio-vga-gl,hostmem=4G,blob=true \
     -display gtk,gl=on,show-cursor=on \
     -usb -device usb-tablet \
     -cdrom callisto.iso
   ```

   Note the memfd memory-backend requirement: `blob=true` needs shared memory. `blob`+`hostmem`
   additionally unlock OpenGL 4.6 in the guest (vs 4.3 default) and are required for Venus
   (Vulkan) if you ever want it. Requires host Linux 6.13+ for blob features; plain virgl GL works
   on any recent host. [14][15]

2. **Plain `virtio-vga` (2D)** — the sane default when the host has no usable GL (headless server,
   CI box, or `-display none`/VNC). Guest falls back to llvmpipe. Fine for "does it boot, does the
   compositor start" smoke tests, miserable for interactive use. wlroots compositors do run on
   llvmpipe.

3. **`qxl`** — legacy SPICE-oriented device, no meaningful 3D path for Wayland guests; avoid for
   new work. Mentioned only because old guides recommend it.

4. **`egl-headless` vs `gtk,gl=on`**: egl-headless works without a host windowing system and was
   historically needed on NVIDIA; per current community experience it's a worse experience than
   gtk/sdl backends (stalls, no power ramping). Use `-display gtk,gl=on` for interactive sessions
   on a desktop host; use `-display none` + serial for CI. SDL (`-display sdl,gl=on`) is a valid
   gtk alternative. [16]

### KVM

`-enable-kvm` (or `-accel kvm`) requires `/dev/kvm` access; in containers you must pass
`--device /dev/kvm`. Without KVM the boot is 10–50x slower — acceptable for CI smoke tests, painful
otherwise. `-machine q35` + `-cpu host` is the modern default (q35 needed for some virtio/PCIe
paths; `host` exposes host CPU features). [15]

### Suggested Makefile target split

```
make run        # interactive: virtio-vga-gl, gtk gl=on, KVM required, usb-tablet
make run-safe   # fallback: plain virtio-vga, no GL (for hosts without working virgl)
make smoke      # headless: -display none -serial stdio, no KVM requirement, timeout-wrapped
```

### Headless CI smoke-testing of live ISOs

Established pattern (used by Debian openQA, Fedora, and smaller projects):

- Boot with `-display none -serial mon:stdio` (or `-serial file:boot.log`), kernel cmdline in the
  ISO's boot config already carrying `console=ttyS0` so systemd and the live session log to serial.
  For live-build images you control the boot menu entries — add a `console=ttyS0` entry or append
  it in a test-only boot stanza.
- Drive interaction with **expect scripts or Python `pexpect`** against the serial console: wait
  for login prompt or shell, run commands, assert on output. This is how most non-openQA projects
  do it.
- The industrial-strength version is **openQA** (what Debian feeds reproducible live images into
  [6]) — needles + needle matching on screenshots; overkill until the project matures.
- **First-boot markers**: cheap and effective — have the live system write a sentinel
  (`systemd` unit or rc-local equivalent that does `echo BOOTED > /dev/ttyS0` or touches a marker
  and prints a unique string like `CALLISTO_BOOT_OK`). The CI script greps the serial log for the
  sentinel with a timeout. Combine with `-no-reboot` and a QEMU pidfile so CI can kill the VM.
- For Wayland-compositor verification headlessly: boot, then over serial run
  `WLR_BACKENDS=headless`-independent checks — but since Hyprland inside the VM runs on the
  virtio/llvmpipe DRM device regardless of QEMU display backend, the meaningful assertions are:
  compositor process running, `wayland-1` socket exists in `XDG_RUNTIME_DIR`, `wlr-randr`/`hyprctl`
  responds. These run fine over serial with `-display none`. [17]

(Uncertainty flag: Hyprland-on-virgl inside QEMU works per hyprwm/Hyprland#1056-era reports, but
Hyprland is aggressive about requiring GLES3.2/dmabuf features; llvmpipe in trixie's Mesa is new
enough to run it. Verify early — this is Callisto's biggest test-environment risk.)

## 5. Licensing/attribution conventions for a Debian derivative

Debian has explicit guidelines (`wiki.debian.org/Derivatives/Guidelines`, plus the derivatives
census). What Callisto must do:

**Required/expected de-branding** (Debian asks derivatives to eliminate user confusion with
vanilla Debian):

1. **`os-release`** — the primary identity mechanism, shipped in `base-files`. Debian builds it by
   sed-substituting a template in `debian/rules`; derivatives override it. Required shape per
   `os-release(5)` and derivative practice:
   ```
   NAME="Callisto"
   ID=callisto
   ID_LIKE=debian
   PRETTY_NAME="Callisto 1.0"
   VERSION_ID=...
   VERSION_CODENAME= (optional; can reference trixie lineage or your own)
   HOME_URL / DOCUMENTATION_URL / SUPPORT_URL / BUG_REPORT_URL -> your infra, NOT debian.org
   ```
   Key points: `ID` is your own lowercase identifier; **`ID_LIKE=debian` is the lineage
   declaration** — this is how Ubuntu does it (`ID=ubuntu`, `ID_LIKE=debian`) and it's what tools
   use to know apt/dpkg semantics apply. `/etc/os-release` should be a relative symlink to
   `/usr/lib/os-release` (the vendor-tree location). Never point SUPPORT_URL/BUG_REPORT_URL at
   Debian's BTS. [18][19][20]
2. **`/etc/dpkg/origins/default`** — vendor file declaring your vendor name with `Parent: Debian`.
   Every serious derivative (Ubuntu, Raspberry Pi OS, Devuan) ships this; it's explicitly in the
   derivatives guidelines, and `dpkg-vendor` reads it. Easy to forget, cheap to ship. [21]
3. **`/etc/issue`, `/etc/issue.net`, `/etc/motd`, `/etc/lsb-release`** — base-files ships Debian
   text in all of these; override them via `includes.chroot` overlay or a base-files fork. The
   os-release templates in base-files are substituted at package build time, so overlaying at
   live-build time (includes.chroot) is the pragmatic path for a small derivative — Kali does
   exactly this rather than forking base-files. (Flag: a base-files fork is the "fully correct"
   route; overlay is the pragmatic one most small derivatives use.)
4. **Artwork/trademarks**: don't ship Debian's logo or the Debian name in a way that implies
   endorsement; the name "Debian" is trademarked, swirly logo is restricted. Reference Debian
   factually ("based on Debian 13 (trixie)") — that's normal and welcome.
5. **Modified packages**: if you rebuild any Debian package with changes, guidelines ask for a
   derivative version suffix (e.g. `-1callisto1`), updated Maintainer field with original moved to
   `XSBC-Original-Maintainer`. [21]
6. **License compliance**: everything in Debian main is DFSG-free and redistributable; you must
   keep copyright files intact (`/usr/share/doc/*/copyright` — you get this free), and if you ship
   non-free-firmware be mindful of those licenses (they permit redistribution on Debian media but
   read the firmware licenses). Document your base: ship something like `/etc/callisto-release` or
   a `/usr/share/doc/callisto/BASED-ON` noting the Debian version and snapshot timestamp — this
   doubles as reproducibility metadata.

**In the census spirit**: Debian encourages derivatives to register at the derivatives census and
publish their sources.list; not required, but it's the good-citizen move. [22]

---

## Sources

1. Kali Linux kali-live repo + README, gitlab.com/kalilinux/build-scripts/kali-live (fetched 2026-11)
2. kali-live `build.sh` source (image naming, validation, lb invocation)
3. kali.org docs: "Creating a Custom Kali ISO", "Dojo: Mastering live-build"
4. Kali bug tracker #0009868 — 2026 build-script refresh, flag renames
5. reproducible-builds.org monthly report, March 2025 — "Debian bookworm live images now fully reproducible"
6. rb-general list, Roland Clobus, "Irregular status update…", March 2025 — reproducibility status incl. trixie, openQA feeding, 6-hour DAK window
7. rb-general list, "Recoding the configuration for live-build images", Aug 2021 — the four reproducibility inputs
8. rclobus.nl blog, "Reproducible Debian-live images" — S_D_E before `lb config`, EFI 1980 epoch, diffoscope workflow, snapshot mirror URLs
9. labkiosk distro-builder README — rootful requirement, mknod under rootless, 9P/drvfs COPY rationale, mknod verification command
10. yoe build environment docs — `/dev/loop*` not auto-populated in Docker tmpfs, mknod workaround, podman-vs-docker `/dev` behavior
11. docker/cli issue #2969 — debootstrap in privileged containers unmounting /proc; cap-based alternatives
12. bigiron.cc mmdebstrap guide — unshare mode, squashfs output, S_D_E reproducibility, apt resolver; mmdebstrap vs debootstrap table
13. reproducible-builds.org SOURCE_DATE_EPOCH docs — git-derived S_D_E one-liner, parsing guidance
14. QEMU official virtio-gpu documentation — device variants, blob/hostmem/venus requirements, host kernel/lib versions
15. peppergrayxyz gist "QEMU with VirtIO GPU Vulkan Support" — canonical virt=io-vga-gl+blob invocation with memfd; egl-headless NVIDIA note
16. Linux Containers forum incus DE thread — egl-headless vs gtk/sdl backend experience
17. kraxel.org "VGA and other display devices in qemu" — virtio-vga feature matrix
18. os-release(5) manpage (Debian trixie/freedesktop) — field semantics, ID_LIKE, /usr/lib/os-release vs /etc symlink
19. wiki.debian.org/Derivatives/Guidelines (via raspberrypi issue discussion) — de-branding requirements incl. base-files/os-release
20. sources.debian.org base-files debian/rules — how os-release is generated in Debian proper
21. chainguard.dev "Docker Hodgepodge Images" — dpkg vendor file expectations, maintainer-field conventions, real derivative examples
22. debian.org/derivatives — derivative definition, census, what Debian asks of derivatives

## Open uncertainties

- Parrot OS repo structure detail is thin in public docs; Kali treated as canonical.
- Hyprland-on-virgl/llvmpipe inside QEMU is the biggest unverified technical risk; needs a day-one
  smoke test before committing to a graphics stack for `make run`.
- Whether Callisto should overlay base-files identity files vs fork base-files is unresolved —
  overlay is pragmatic, fork is cleaner for a "real" distro.
- Fedora/Ubuntu sections are deliberately shallow — their tooling (lorax/pungi, livecd-rootfs)
  doesn't transfer to a live-build project; noted for completeness only.
