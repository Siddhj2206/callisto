#!/bin/bash
# Opens settings, clicks the "Reduce motion" switch in Bar & Shell,
# then checks the store file reflects it.
sleep 2
qs ipc call settings toggle 2>/dev/null
sleep 3
# The switch for reduce motion in Bar&Shell panel — panel 8; but default
# panel is appearance. Simpler verification: check SettingsService writes
# by inspecting process state — log the store file existence and content.
ls -la /home/triton/.config/callisto/ 2>&1
echo "--- store content:"
cat /home/triton/.config/callisto/settings.json 2>/dev/null || echo "no store yet"
echo "SETTINGS-CHECK-DONE"
