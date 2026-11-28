#!/usr/bin/env bash
# build-debs.sh — the Debian packages Callisto patches, into
# live-build/config/packages.chroot, from where live-build installs them.
#
# Only Hyprland for now (patches/hyprland). Compiling it takes a quarter of an
# hour or more; the image is kept until its Dockerfile or a patch changes.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/live-build/config/packages.chroot"

hash="$(cat "$REPO/containers/hyprland.Dockerfile" "$REPO"/patches/hyprland/* | sha256sum | cut -c1-12)"
image="localhost/callisto-hyprland:$hash"

if ! podman image exists "$image"; then
    echo "==> Building the patched Hyprland (a while, once)"
    podman build -f "$REPO/containers/hyprland.Dockerfile" -t "$image" "$REPO"
fi

rm -rf "$OUT"
mkdir -p "$OUT"
podman run --rm -v "$OUT:/dst:z" "$image" sh -c 'cp /out/*.deb /dst/'
echo "==> $(cd "$OUT" && echo ./*.deb)"
