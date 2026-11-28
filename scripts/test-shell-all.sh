#!/usr/bin/env bash
# test-shell-all.sh — load every entry point and gallery page in the headless
# harness. A screenshot and a log per name are left in .out/shell-all/.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/.out/shell-all"
mkdir -p "$OUT"
failed=()

run() {
    local name="$1"
    shift
    if "$REPO/scripts/test-shell.sh" "$@" --shot "$OUT/$name.png" > "$OUT/$name.log" 2>&1; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        tail -20 "$OUT/$name.log"
        failed+=("$name")
    fi
}

for entry in shell greeter settings-app; do
    run "$entry" --entry "$entry.qml"
done
for page in "$REPO"/shell/triton/gallery/*.qml; do
    page="$(basename "$page" .qml)"
    run "gallery-$page" --gallery "$page"
done

if (( ${#failed[@]} )); then
    echo "failed: ${failed[*]}" >&2
    exit 1
fi
