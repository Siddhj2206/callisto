# vm-drive.sh — drive a running QEMU machine through its monitor socket.
# Source it after setting MON_SOCK (the socket) and OUT_DIR (for screenshots):
#
#   mon <command>      any monitor command
#   key <name>         one key, QEMU's sendkey names (meta_l-ret)
#   type_text <text>   a string, on a US layout
#   shot <name>        screenshot to OUT_DIR/<name>.png (needs Pillow)
#
# shellcheck shell=bash

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
    # QEMU sendkey names for the full printable ascii set (us layout).
    # Punctuation needs explicit names — bare characters are ignored.
    local text="$1"
    for (( i=0; i<${#text}; i++ )); do
        c="${text:i:1}"
        case "$c" in
            [a-z]) key "$c" ;;
            [A-Z]) key "shift-$(echo "$c" | tr 'A-Z' 'a-z')" ;;
            [0-9]) key "$c" ;;
            " ") key "spc" ;;
            ".") key "dot" ;;
            ",") key "comma" ;;
            "/") key "slash" ;;
            "\\") key "backslash" ;;
            "-") key "minus" ;;
            "=") key "equal" ;;
            ";") key "semicolon" ;;
            "'") key "apostrophe" ;;
            "\`") key "grave_accent" ;;
            "[") key "bracket_left" ;;
            "]") key "bracket_right" ;;
            "!") key "shift-1" ;;
            "@") key "shift-2" ;;
            "#") key "shift-3" ;;
            "\$") key "shift-4" ;;
            "%") key "shift-5" ;;
            "^") key "shift-6" ;;
            "&") key "shift-7" ;;
            "*") key "shift-8" ;;
            "(") key "shift-9" ;;
            ")") key "shift-0" ;;
            "_") key "shift-minus" ;;
            "+") key "shift-equal" ;;
            ":") key "shift-semicolon" ;;
            "\"") key "shift-apostrophe" ;;
            "~") key "shift-grave_accent" ;;
            "{") key "shift-bracket_left" ;;
            "}") key "shift-bracket_right" ;;
            "|") key "shift-backslash" ;;
            "<") key "shift-comma" ;;
            ">") key "shift-dot" ;;
            "?") key "shift-slash" ;;
            *) echo "type_text: skipping unmappable char: $c" >&2 ;;
        esac
    done
}
