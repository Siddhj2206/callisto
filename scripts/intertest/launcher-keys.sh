# Drives launcher keyboard interaction inside the harness container.
# Waits for focus, types, navigates, then presses Escape — the log after
# capture should show QUERY/SELECTION/CLOSED lines.
sleep 3
wtype "con" 2>/dev/null
sleep 1
wtype -k down 2>/dev/null
sleep 0.5
wtype -k down 2>/dev/null
sleep 0.5
wtype -k up 2>/dev/null
sleep 0.5
wtype -k escape 2>/dev/null
sleep 1
