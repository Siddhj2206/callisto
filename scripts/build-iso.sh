#!/usr/bin/env bash
# build-iso.sh — reproducible Callisto live ISO build.
#
# The build runs inside the callisto-iso-builder container image (see
# Dockerfile.builder) so the host distribution and its package versions never
# leak into the ISO. live-build runs rootless — verified end-to-end, iso-hybrid needs no loop devices.
#
# Inputs that determine the output bit-for-bit:
#   * the git state of this repository
#   * SOURCE_DATE_EPOCH (pinned snapshot timestamps in release builds)
#   * the Debian mirror (may be repointed at snapshot.debian.org)
#
# Usage:
#   scripts/build-iso.sh            # build with default mirrors
#   CLEAN=1 scripts/build-iso.sh    # lb clean first (fresh bootstrap)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="callisto-iso-builder"
ISO_OUT="$REPO_ROOT/callisto-amd64.hybrid.iso"

# Reproducible timestamps: derive from the last commit so two builds of the
# same commit agree. live-build reads this before `lb config`.
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$REPO_ROOT" log -1 --format=%ct 2>/dev/null || date +%s)}"

echo "==> SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH ($(date -ud "@$SOURCE_DATE_EPOCH" +%Y-%m-%dT%H:%M:%SZ))"

# --- Stage configuration ------------------------------------------------------
echo "==> Syncing configuration into includes.chroot"
"$REPO_ROOT/scripts/sync-configs.sh"

# --- Build container image ----------------------------------------------------
if ! podman image exists "$IMAGE"; then
    echo "==> Building $IMAGE"
    podman build -f "$REPO_ROOT/Dockerfile.builder" -t "$IMAGE" "$REPO_ROOT"
fi

# --- Run live-build inside the container ---------------------------------------
# Rootless podman works for iso-hybrid builds. SELinux hosts
# need :z on the volume. The repo is mounted at /work, live-build's own state
# stays in live-build/.
echo "==> Running live-build in container (this takes a while on first build)"
podman run --rm --privileged \
    -v "$REPO_ROOT:/work:z" \
    -e SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
    -e CLEAN="${CLEAN:-0}" \
    "$IMAGE" -c '
        set -euo pipefail
        cd /work/live-build
        if [[ "$CLEAN" == "1" ]]; then lb clean; fi
        lb config
        lb bootstrap
        # Rootless containers cannot make device nodes, so the chroot has plain
        # files there: whatever is sent to "/dev/null" piles up and gets read
        # back (it broke the aspell setup). Lend it the real ones while
        # packages are installed.
        nodes="null zero full random urandom tty"
        for node in $nodes; do
            touch "chroot/dev/$node"
            mount --bind "/dev/$node" "chroot/dev/$node"
        done
        lb chroot
        for node in $nodes; do umount "chroot/dev/$node"; : >"chroot/dev/$node"; done
        lb installer
        lb binary
        lb source
    '

# --- Collect artifact -----------------------------------------------------------
if [[ -f "$REPO_ROOT/live-build/callisto-amd64.hybrid.iso" ]]; then
    mv "$REPO_ROOT/live-build/callisto-amd64.hybrid.iso" "$ISO_OUT"
    (cd "$REPO_ROOT" && sha256sum "$(basename "$ISO_OUT")" > SHA256SUMS)
    echo "==> Built: $ISO_OUT"
    echo "==> Checksum: $(cut -d' ' -f1 < "$REPO_ROOT/SHA256SUMS")"
else
    echo "!! ERROR: expected ISO not found — inspect live-build output above" >&2
    exit 1
fi
