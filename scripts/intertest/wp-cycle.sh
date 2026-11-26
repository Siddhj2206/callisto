#!/bin/bash
sleep 2
qs -c triton ipc call wallpaper toggle
sleep 2
# can't send keys to qs ipc — but we can verify preview channel by
# simulating: picker open already proves overlay; now check generative
# desktop by writing store directly then watching
mkdir -p /home/triton/.config/callisto
echo '{"appearance":{"wallpaper":"","wallpaperKind":"dusk"}}' > /home/triton/.config/callisto/settings.json
sleep 3
