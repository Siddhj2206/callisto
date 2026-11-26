#!/bin/bash
sleep 2
qs -p /triton/shell.qml ipc call settings toggle 2>/dev/null || qs ipc -c triton call settings toggle 2>/dev/null
sleep 3
