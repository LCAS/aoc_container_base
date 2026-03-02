#!/bin/bash

echo
echo "****************************************************************************************************************************************"
echo "AOC VNC container starting..."
echo "****************************************************************************************************************************************"

sudo rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 > /dev/null 2>&1
screen -dmS turbovnc bash -c '/opt/TurboVNC/bin/vncserver :1 -depth 24 -noxstartup -securitytypes TLSNone,X509None,None 2>&1 | tee /tmp/vnc.log; read -p "Press any key to continue..."'

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

