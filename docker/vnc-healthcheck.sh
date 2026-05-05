#!/bin/bash
# VNC container health check
# Verifies that all VNC stack components are operational:
#   1. X11 display :1 is available (catches corrupt x11 volume state)
#   2. noVNC web interface is serving on port 5801

# Check X11 display is responding
if ! xdpyinfo -display :1 >/dev/null 2>&1; then
    echo "UNHEALTHY: X11 display :1 is not available" >&2
    exit 1
fi

# Check noVNC web interface (also confirms TurboVNC is running since noVNC proxies to it)
if ! curl -sf http://localhost:5801/vnc.html >/dev/null; then
    echo "UNHEALTHY: noVNC web interface is not accessible on port 5801" >&2
    exit 1
fi

echo "HEALTHY: X11 display :1 and noVNC are operational"
exit 0
