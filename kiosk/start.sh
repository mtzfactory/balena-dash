#!/usr/bin/bash

# check GPU mem setting for Raspberry Pi
if [[ $BALENA_DEVICE_TYPE == *"raspberry"* ]]; 
  then
  if [ "$(vcgencmd get_mem gpu | grep -o '[0-9]\+')" -lt 128 ]
    then
      echo -e "\033[91mWARNING: GPU MEMORY TOO LOW"
  fi
fi

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket


sed -i -e 's/console/anybody/g' /etc/X11/Xwrapper.config
echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
dpkg-reconfigure xserver-xorg-legacy


# if FLAGS env var is not set, use default 
if [[ -z ${FLAGS+x} ]]
  then
    echo "Using default chromium flags"
    export FLAGS="--kiosk  --disable-dev-shm-usage --ignore-gpu-blacklist --enable-gpu-rasterization --force-gpu-rasterization  --autoplay-policy=no-user-gesture-required --start-fullscreen"
fi

#create start script for X11
echo "#!/bin/bash" > /home/chromium/xstart.sh

# rotate screen if env variable is set [normal, inverted, left or right]
if [[ ! -z "$ROTATE_DISPLAY" ]]; then
  echo "(sleep 3 && xrandr -o $ROTATE_DISPLAY) &" >> /home/chromium/xstart.sh
fi

# if no window size has been specified, find the framebuffer size and use that
if [[ -z ${WINDOW_SIZE+x} ]]
  then
    export WINDOW_SIZE=$( cat /sys/class/graphics/fb0/virtual_size )
    echo "Using fullscreen: $WINDOW_SIZE"
fi

echo "xset s off -dpms" >> /home/chromium/xstart.sh

echo "chromium-browser $FLAGS --app=$LAUNCH_URL  --window-size=$WINDOW_SIZE" >> /home/chromium/xstart.sh

chmod 770 /home/chromium/*.sh 
chown chromium:chromium /home/chromium/xstart.sh


# Start Tohora
cd /home/chromium/tohora && ./tohora 8080 /home/chromium/launch.sh &
# wait for it
sleep 3


# Check if we have a GALLERY_URL set, otherwise load LAUNCH_URL var
if [[ ! -z ${GALLERY_URL} ]]
  then
    echo "Loading gallery"
    LAUNCH_URL="file:///home/chromium/public_html/index.html"
fi


if [[ ! -z ${LAUNCH_URL+x} ]]
  then
    sleep 5
    wget --post-data "url=$LAUNCH_URL" http://localhost:8080/launch/ >/dev/null 2>&1
fi


tail -f /dev/null

while : ; do echo "${MESSAGE=Idling...}"; sleep ${INTERVAL=600}; done