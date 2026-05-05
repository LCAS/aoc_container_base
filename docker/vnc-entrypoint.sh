#!/bin/bash

echo
echo "****************************************************************************************************************************************"
echo "AOC VNC container starting..."
echo "****************************************************************************************************************************************"

# --- X11 volume cleanup ---
# The x11 volume may contain stale lock files and sockets from a previous (crashed) run.
# Clear them so TurboVNC can start cleanly.
cleanup_x11() {
    local had_stale=false

    if [ -e /tmp/.X1-lock ]; then
        echo "  [x11] Found stale lock file /tmp/.X1-lock — removing..."
        rm -f /tmp/.X1-lock || sudo rm -f /tmp/.X1-lock
        if [ -e /tmp/.X1-lock ]; then
            echo "  [x11] WARNING: failed to remove /tmp/.X1-lock — x11 volume may be in a corrupt state." >&2
        else
            echo "  [x11] Removed stale lock file."
            had_stale=true
        fi
    fi

    if [ -e /tmp/.X11-unix/X1 ]; then
        echo "  [x11] Found stale socket /tmp/.X11-unix/X1 — removing..."
        rm -f /tmp/.X11-unix/X1 || sudo rm -f /tmp/.X11-unix/X1
        if [ -e /tmp/.X11-unix/X1 ]; then
            echo "  [x11] WARNING: failed to remove /tmp/.X11-unix/X1 — x11 volume may be in a corrupt state." >&2
        else
            echo "  [x11] Removed stale socket."
            had_stale=true
        fi
    fi

    if $had_stale; then
        echo "  [x11] Stale X11 files from previous run cleared successfully."
    else
        echo "  [x11] No stale X11 files found."
    fi

    # Ensure the socket directory has the correct sticky-bit permissions
    chmod 1777 /tmp/.X11-unix 2>/dev/null || sudo chmod 1777 /tmp/.X11-unix 2>/dev/null || true
}

echo "Checking x11 volume state..."
cleanup_x11

# --- Start TurboVNC ---
VNC_STARTUP_TIMEOUT=30   # seconds to wait for VNC display to come up

start_turbovnc() {
    echo "Starting TurboVNC server on display :1..."
    screen -dmS turbovnc bash -c '/opt/TurboVNC/bin/vncserver :1 -depth 24 -noxstartup -securitytypes TLSNone,X509None,None 2>&1 | tee /tmp/vnc.log; read -p "Press any key to continue..."'

    echo "Waiting for display :1 to become available (timeout: ${VNC_STARTUP_TIMEOUT}s)..."
    local max_iterations=$(( VNC_STARTUP_TIMEOUT * 2 ))  # 0.5s per iteration
    local waited=0
    while ! xdpyinfo -display :1 2>/dev/null >/dev/null; do
        sleep 0.5
        waited=$((waited + 1))
        if [ "$waited" -ge "$max_iterations" ]; then
            return 1
        fi
    done
    return 0
}

if ! start_turbovnc; then
    echo "" >&2
    echo "ERROR: TurboVNC failed to start within ${VNC_STARTUP_TIMEOUT}s." >&2
    echo "  This is often caused by stale files left in the x11 volume from a previous run." >&2
    if [ -s /tmp/vnc.log ]; then
        echo "--- VNC server log (/tmp/vnc.log) ---" >&2
        cat /tmp/vnc.log >&2
        echo "--- End of VNC server log ---" >&2
    else
        echo "  (no VNC log available at /tmp/vnc.log)" >&2
    fi

    echo "" >&2
    echo "Attempting automatic recovery: cleaning up x11 volume and retrying..." >&2
    screen -S turbovnc -X quit 2>/dev/null || true
    cleanup_x11

    if ! start_turbovnc; then
        echo "" >&2
        echo "FATAL: TurboVNC failed to start even after x11 volume cleanup." >&2
        if [ -s /tmp/vnc.log ]; then
            echo "--- VNC server log (/tmp/vnc.log) ---" >&2
            cat /tmp/vnc.log >&2
            echo "--- End of VNC server log ---" >&2
        fi
        echo "" >&2
        echo "To recover manually, remove the x11 volume and restart containers." >&2
        exit 1
    fi

    echo "Recovery successful: TurboVNC started after x11 volume cleanup."
fi

echo "Display :1 is up."

# --- Start XFCE4 ---
XFCE_STARTUP_TIMEOUT=30   # seconds to wait for xfce4-session to set DBUS_SESSION_BUS_ADDRESS

echo "Starting xfce4..."
screen -dmS xfce4 bash -c 'DISPLAY=:1 /usr/bin/xfce4-session 2>&1 | tee /tmp/xfce4.log'

xfce_max_iterations=$(( XFCE_STARTUP_TIMEOUT * 2 ))  # 0.5s per iteration
xfce_waited=0
while [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; do
    if pgrep xfce4-session > /dev/null; then
        XFCE_PID=$(pgrep xfce4-session)
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$XFCE_PID/environ|cut -d= -f2-|tr -d '\0')
    fi
    sleep 0.5
    xfce_waited=$((xfce_waited + 1))
    if [ "$xfce_waited" -ge "$xfce_max_iterations" ]; then
        echo "" >&2
        echo "ERROR: xfce4-session did not become ready within ${XFCE_STARTUP_TIMEOUT}s." >&2
        if [ -s /tmp/xfce4.log ]; then
            echo "--- xfce4 log (/tmp/xfce4.log) ---" >&2
            cat /tmp/xfce4.log >&2
            echo "--- End of xfce4 log ---" >&2
        fi
        exit 1
    fi
done
echo "xfce4 up."

echo "Starting novnc ${NOVNC_VERSION}..."
screen -dmS novnc bash -c '/usr/local/novnc/noVNC-${NOVNC_VERSION}/utils/novnc_proxy --vnc localhost:5901 --listen 5801 2>&1 | tee /tmp/novnc.log'

DISPLAY=:1 xhost +local: 2>/dev/null
echo "xhost +local: applied to :1"

# set the wallpaper
(
  export DISPLAY=:1
  CURRENT_USER="$(id -un)"
  VNC_WALLPAPER=${VNC_WALLPAPER:-lcas}
  WALLPAPER="/usr/share/backgrounds/xfce/${VNC_WALLPAPER}.jpg"
  base="/backdrop/screen0/monitorVNC-0/workspace0"

  xfconf-query -c xfce4-desktop -p "${base}/image-show" -n -t bool -s true
  xfconf-query -c xfce4-desktop -p "${base}/image-style" -n -t int -s 5
  xfconf-query -c xfce4-desktop -p "${base}/image-path" -n -t string -s "$WALLPAPER"
  xfconf-query -c xfce4-desktop -p "${base}/last-image" -n -t string -s "$WALLPAPER"
  xfconf-query -c xfce4-desktop -p "${base}/last-single-image" -n -t string -s "$WALLPAPER"

  # xfdesktop --reload
) &

echo 
echo "****************************************************************************************************************************************"
echo "VNC Desktop ready. Open your browser at http://localhost:5801/vnc.html?autoconnect=true or another hostname and port you may have forwarded."
echo "****************************************************************************************************************************************"
echo

echo >&2

# This script can either be a wrapper around arbitrary command lines,
# or it will simply exec bash if no arguments were given
if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  exec "$@"
fi

