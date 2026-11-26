#!/bin/bash
# create file BEFORE shell notices, then modify it twice
mkdir -p /home/triton/.config/callisto
echo '{"color":{"dark":{"primary":"#00FFFF"}}}' > /home/triton/.config/callisto/tokens.json
sleep 1
echo '{"color":{"dark":{"primary":"#FF00FF"}}}' > /home/triton/.config/callisto/tokens.json
sleep 1
echo '{"color":{"dark":{"primary":"#FFFF00"}}}' > /home/triton/.config/callisto/tokens.json
sleep 3
