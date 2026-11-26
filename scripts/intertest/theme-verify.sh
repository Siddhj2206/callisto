#!/bin/bash
sleep 2
# write a custom accent through the same channel the settings app uses
mkdir -p /home/triton/.config/callisto
cat > /home/triton/.config/callisto/settings.json <<JSON
{"appearance":{"accent":"#E58A4B","mode":"dark","material":"glass"},"shell":{"clockFormat":"12h"}}
JSON
sleep 4
