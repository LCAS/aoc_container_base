#!/bin/bash

echo
echo "****************************************************************************************************************************************"
echo "AOC VNC container starting..."
echo "****************************************************************************************************************************************"


echo "starting turbovnc"
sudo rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 > /dev/null 2>&1
screen -dmS turbovnc bash -c 'VGL_DISPLAY=egl VGL_FPS=30 /opt/TurboVNC/bin/vncserver :1 -depth 24 -noxstartup -securitytypes TLSNone,X509None,None 2>&1 | tee /tmp/vnc.log; read -p "Press any key to continue..."'
# wait for VNC to be running

echo "waiting for display to be up"
while ! xdpyinfo -display :1 2> /dev/null > /dev/null; do
    sleep .1
done
echo "display is up"

echo "starting xfce4"
screen -dmS xfce4 bash -c 'DISPLAY=:1 /usr/bin/xfce4-session 2>&1 | tee /tmp/xfce4.log'
while [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; do
    if pgrep xfce4-session > /dev/null; then
        XFCE_PID=$(pgrep xfce4-session)
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$XFCE_PID/environ|cut -d= -f2-|tr -d '\0')
    fi
    sleep .1
done
echo "xfce4 up"

echo "starting novnc ${NOVNC_VERSION}"
screen -dmS novnc bash -c '/usr/local/novnc/noVNC-${NOVNC_VERSION}/utils/novnc_proxy --vnc localhost:5901 --listen 5801 2>&1 | tee /tmp/novnc.log'

DISPLAY=:1 xhost +local: 2>/dev/null
echo "xhost +local: applied to :1"

# ensure wallpaper/panels are applied; start xfdesktop if missing
( 
  sleep 8
  export DISPLAY=:1
  export DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"

  # start xfdesktop if not running so it can apply the wallpaper
  if ! pgrep -u "$USER" xfdesktop > /dev/null 2>&1; then
    xfdesktop --daemon > /dev/null 2>&1 || true
  fi

  WALLPAPER="/usr/share/backgrounds/xfce/aoc_wallpaper.jpg"

  # apply wallpaper for monitor0 (add others if needed)
  xfconf-query -c xfce4-desktop -np /backdrop/screen0/monitor0/image-path -t string -s "$WALLPAPER" > /dev/null 2>&1
  xfconf-query -c xfce4-desktop -np /backdrop/screen0/monitor0/last-image -t string -s "$WALLPAPER" > /dev/null 2>&1
  xfconf-query -c xfce4-desktop -np /backdrop/screen0/monitor0/workspace0/last-image -t string -s "$WALLPAPER" > /dev/null 2>&1
  xfconf-query -c xfce4-desktop -np /backdrop/screen0/monitor0/image-show -t bool -s true > /dev/null 2>&1

  # remove secondary panel if present
  xfconf-query -c xfce4-panel -p /panels/panel-2 -r > /dev/null 2>&1 || true
  xfce4-panel --reload > /dev/null 2>&1 || true

  xfdesktop --reload > /dev/null 2>&1 || true
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

