#!/bin/bash
sleep 2
mkdir -p /home/triton/.config/callisto
# write through the SAME path the settings app uses: the store file + engine
# — but the service watches the file; just verify the apply runs
cat > /home/triton/.config/callisto/settings.json <<JSON
{"appearance":{"mode":"light","accent":"wallpaper","material":"glass"}}
JSON
echo "store written"
ls -la /home/triton/.config/callisto/ >> /home/triton/inter-debug.txt 2>&1
sleep 5
cat /home/triton/.config/callisto/tokens.json 2>/dev/null | grep -m1 active_mode >> /home/triton/inter-debug.txt 2>&1
