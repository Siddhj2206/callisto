#!/usr/bin/env bash
# push-to-vm.sh — stage current repo shell+config into the QEMU 9p share so
# refresh-shell.sh inside the VM picks them up. Iteration without rebuilds.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARE="$REPO_ROOT/.isotest/share"
rm -rf "$SHARE/shell-triton"
cp -r "$REPO_ROOT/shell/triton" "$SHARE/shell-triton"
cp "$REPO_ROOT/configs/hypr/hyprland.lua" "$SHARE/hyprland.lua"
cp "$REPO_ROOT/scripts/engine/callisto-apply" "$SHARE/callisto-apply"
echo "staged → $SHARE"
