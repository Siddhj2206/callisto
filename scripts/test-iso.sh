#!/usr/bin/env bash
# test-iso.sh — boot the ISO in QEMU and capture proof-of-life screendumps.
#
# Fully automated: no display needed. The QEMU monitor socket drives keys
# and screenshots; the serial console (console=ttyS0 in bootappend) streams
# the boot log to a file.
#
#   scripts/test-iso.sh [iso-path] [wait-seconds]
#
# Artifacts land in .isotest/: serial.log, stage-*.png.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$REPO_ROOT/callisto-amd64.hybrid.iso}"
OUT="$REPO_ROOT/.isotest"
MON="$OUT/monitor.sock"
SERIAL="$OUT/serial.log"

mkdir -p "$OUT"
rm -f "$MON" "$SERIAL"

QEMU="${QEMU:-qemu-system-x86_64}"

echo "==> Booting $ISO (headless, serial logging)"
"$QEMU" \
    -enable-kvm -smp 4 -cpu host -machine q35 -m 4G \
    -object memory-backend-memfd,id=mem,size=4G \
    -cdrom "$ISO" -boot d \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -device virtio-vga \
    -display none \
    -serial "file:$SERIAL" \
    -monitor "unix:$MON,server,nowait" \
    -daemonize 2>/dev/null

echo "==> VM up — monitor at $MON"

# helper functions get exported as a sourceable snippet
cat > "$OUT/drive.sh" <<'DRIVE'
#!/usr/bin/env bash
# sourced by interaction scripts: mon <cmd>, shot <name>, type_text <string>, key <key>

mon() {
    python3 - "$MON_SOCK" "$1" <<'PYEOF'
import socket, sys, time
sock, cmd = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock)
s.settimeout(2)
time.sleep(0.15)
try: s.recv(4096)
except Exception: pass
s.sendall((cmd + "\n").encode())
time.sleep(0.5)
s.close()
PYEOF
}

shot() {
    mon "screendump $OUT_DIR/$1.ppm"
    sleep 1
    python3 -c "
from PIL import Image
try:
    im = Image.open('$OUT_DIR/$1.ppm').convert('RGB')
    im.save('$OUT_DIR/$1.png')
    print('shot: $1.png', im.size)
except Exception as e:
    print('shot failed:', e)"
}

key() { mon "sendkey $1"; sleep 0.4; }

type_text() {
    local text="$1"
    for (( i=0; i<${#text}; i++ )); do
        c="${text:i:1}"
        case "$c" in
            [a-z]) key "$c" ;;
            [A-Z]) key "shift-$(echo "$c" | tr 'A-Z' 'a-z')" ;;
            [0-9]) key "$c" ;;
            " ") key "spc" ;;
            ".") key "dot" ;;
            "/") key "slash" ;;
            "-") key "minus" ;;
            *) key "$c" ;;
        esac
    done
}
DRIVE
chmod +x "$OUT/drive.sh"
echo "==> VM running. Drive it with:"
echo "    export MON_SOCK=$MON OUT_DIR=$OUT"
echo "    source $OUT/drive.sh"
