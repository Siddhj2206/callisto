#!/usr/bin/env bash
# run-qemu.sh — boot the Callisto ISO in QEMU.
#
# Default mode uses virtio-vga-gl (virgl) with a GTK display so Hyprland gets
# real GPU acceleration where the host supports it. --sw falls back to plain
# virtio-vga + llvmpipe software rendering for hosts without working GL.
#
# Usage:
#   scripts/run-qemu.sh             # accelerated
#   scripts/run-qemu.sh --sw        # software rendering fallback
#   scripts/run-qemu.sh --headless  # serial console only (CI smoke test)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="$REPO_ROOT/callisto-amd64.hybrid.iso"

if [[ ! -f "$ISO" ]]; then
    echo "!! $ISO not found — run 'make iso' first" >&2
    exit 1
fi

MODE="accel"
for arg in "$@"; do
    case "$arg" in
        --sw) MODE="sw" ;;
        --headless) MODE="headless" ;;
        *) echo "!! unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# memfd memory backend in all modes: virtio-vga-gl blob resources require it,
# and using it everywhere keeps the modes as close to each other as possible.
BASE=(
    qemu-system-x86_64
    -enable-kvm
    -smp 4
    -cpu host
    -machine q35,memory-backend=mem
    -object memory-backend-memfd,id=mem,size=4G
    -cdrom "$ISO"
    -boot d
    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0
)

case "$MODE" in
    accel)
        # blob=true gives the guest proper virgl memory objects; hostmem is
        # the shared memory region the GPU blobs are staged through.
        exec "${BASE[@]}" \
            -device virtio-vga-gl,blob=true,hostmem=4G \
            -display gtk,gl=on
        ;;
    sw)
        exec "${BASE[@]}" \
            -device virtio-vga \
            -display gtk
        ;;
    headless)
        # Serial-only boot; pair with console=ttyS0 in bootappend for CI.
        exec "${BASE[@]}" \
            -device virtio-vga \
            -display none \
            -serial stdio
        ;;
esac
