#!/bin/bash
set -euo pipefail


export USER_NAME="darryn"
export USER_UID="$(id -u "$USER_NAME")"
export USER_GID="$(id -g "$USER_NAME")"
export DISPLAY_NUM=":55"
export VT="vt7"

echo "[root] Ensuring machine-id"
if [ ! -s /etc/machine-id ]; then
  dbus-uuidgen --ensure=/etc/machine-id
fi

echo "[root] Preparing /run/user/${USER_UID}"
mkdir -p "/run/user/${USER_UID}"
chown "${USER_UID}:${USER_GID}" "/run/user/${USER_UID}"
chmod 700 "/run/user/${USER_UID}"

echo "[root] Preparing pulse"
sed -i "s|^#load-module module-alsa-sink.*$|load-module module-alsa-sink device=hw:0,3 sink_name=onkyo channels=8 channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right,side-left,side-right rate=48000\nset-default-sink onkyo|" \
        /etc/pulse/default.pa

#echo "[root] Start X"
/usr/lib/Xorg ${VT} ${DISPLAY_NUM} \
  -config /etc/X11/xorg.conf \
  -noreset \
  -novtswitch \
  -sharevts \
  -nolisten tcp \
  -seat seat0 \
  -keeptty \
  +extension XTEST \
  +extension XInputExtension \
  -verbose &

# Wait for X to start (no xdpyinfo dependency)
echo "[root] Waiting for X socket..."
sleep 1
for i in {1..100}; do
  if [ -S "/tmp/.X11-unix/X${DISPLAY_NUM#:}" ]; then
    break
    echo "[root] Xorg socket is ready"
  fi
  sleep 0.1
done

export DISPLAY="${DISPLAY_NUM}"
export XDG_RUNTIME_DIR="/run/user/${USER_UID}"

echo "[root] Dropping to ${USER_NAME} to start WM/apps"
exec sudo -u "${USER_NAME}" -E /usr/local/bin/start-x.sh
