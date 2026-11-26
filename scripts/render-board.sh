#!/bin/sh
# Render a design board (*.dc.html) to a PNG at 1:1 pixel scale.
#
# Boards are the visual spec. The verification loop measures our shell
# renders against these images, so they must be pixel-exact: headless
# chromium, no scaling, window sized to the board's .root element.
#
# Usage: render-board.sh Launcher [out.png] [widthxheight]
#   Renders references/Launcher.dc.html to /tmp/boardout/launcher.png
#
# Fonts come from the Google Fonts CDN inside the board markup, so the
# container needs network access.

set -e

BOARD="${1:?board name, e.g. Launcher}"
OUT="${2:-/tmp/boardout/$(echo "$BOARD" | tr 'A-Z' 'a-z').png}"
SIZE="${3:-1646,1029}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/references/$BOARD.dc.html"

if [ ! -f "$SRC" ]; then
    echo "render-board: no board at $SRC" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUT")"

podman run --rm --network host \
    -v "$REPO_ROOT/references:/refs:ro,Z" \
    -v "$(dirname "$OUT"):/out:rw,Z" \
    localhost/boardrender \
    chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
        --force-device-scale-factor=1 --hide-scrollbars \
        --window-size="$SIZE" \
        --virtual-time-budget=10000 \
        --screenshot="/out/$(basename "$OUT")" \
        "file:///refs/$BOARD.dc.html" >/dev/null 2>&1

echo "render-board: wrote $OUT"
