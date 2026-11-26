#!/bin/bash
mkdir -p /home/triton/.local/share/applications
cp /triton-intertest/fakeapps/*.desktop /home/triton/.local/share/applications/ 2>/dev/null
sleep 2
qs -c triton ipc call launcher toggle
sleep 3
