#!/usr/bin/env bash
# test-iso.sh — smoke test: boot the ISO headless in QEMU, log in on the
# serial console, check that the system and the desktop session are up, and
# take a screenshot. Output in .out/iso/.
#
#   scripts/test-iso.sh [iso-path]
#
# KEEP=1 leaves the machine running, to be driven with scripts/vm-drive.sh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$REPO_ROOT/callisto-amd64.hybrid.iso}"
export OUT_DIR="$REPO_ROOT/.out/iso"
export MON_SOCK="$OUT_DIR/monitor.sock"
QEMU="${QEMU:-qemu-system-x86_64}"

[[ -f "$ISO" ]] || { echo "!! $ISO not found: run 'make iso' first" >&2; exit 1; }
mkdir -p "$OUT_DIR/share"
SERIAL="$OUT_DIR/serial.sock"
rm -f "$MON_SOCK" "$SERIAL" "$OUT_DIR/serial.log" "$OUT_DIR/pid"

echo "==> Booting $ISO"
"$QEMU" \
    -enable-kvm -smp 4 -cpu host -machine q35 -m 4G \
    -cdrom "$ISO" -boot d \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -device virtio-vga \
    -virtfs local,path="$OUT_DIR/share",mount_tag=hostshare,security_model=mapped-xattr \
    -display none \
    -chardev "socket,id=serial,path=$SERIAL,server=on,wait=off,logfile=$OUT_DIR/serial.log" \
    -serial chardev:serial \
    -monitor "unix:$MON_SOCK,server,nowait" \
    -pidfile "$OUT_DIR/pid" \
    -daemonize

stop() { kill "$(cat "$OUT_DIR/pid")" 2>/dev/null || true; }
[[ "${KEEP:-0}" == "1" ]] || trap stop EXIT

echo "==> Checking the booted system"
status=0
python3 "$REPO_ROOT/scripts/smoke-check.py" "$SERIAL" || status=1
# shellcheck source=vm-drive.sh
source "$REPO_ROOT/scripts/vm-drive.sh"
shot desktop

if [[ "${KEEP:-0}" == "1" ]]; then
    echo "==> Still running. To drive it:"
    echo "    export MON_SOCK=$MON_SOCK OUT_DIR=$OUT_DIR; source scripts/vm-drive.sh"
fi
echo "==> Serial console: $OUT_DIR/serial.log"
exit "$status"
