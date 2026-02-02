#!/bin/bash
set -euo pipefail

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DISPLAY="${DISPLAY:-:55}"
export DISPLAY_NUM="${DISPLAY_NUM}"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "[$USER_NAME] Starting session DBus"
DBUS_ADDR="$(dbus-daemon --session \
  --address=unix:path=$XDG_RUNTIME_DIR/bus \
  --fork \
  --print-address=1 | tail -n1)"
export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"

cd "$HOME"

echo "[$USER_NAME] Starting PulseAudio"
pulseaudio --daemonize=yes --exit-idle-time=-1
#pulseaudio --system --daemonize=no --disallow-module-loading --disallow-exit &
export SDL_AUDIODRIVER=pulse
export PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native

echo "[$USER_NAME] Starting window manager"
openbox &
sleep 1

echo "[$USER_NAME] Starting xterm (debug)"
xterm &

echo "[$USER_NAME] Starting VNC"
x0vncserver --display "${DISPLAY}" \
  -rfbport 5902 \
  -rfbauth "$HOME/.config/vncpasswd" &

echo "[$USER_NAME] Starting steam"
export STEAM_FORCE_DESKTOPUI_SCALING=1
export DXVK_FULLSCREEN=1

steam -bigpicture \
      -fullscreen \
      -steamos

echo "[$USER_NAME Sleeping forever"
sleep infinity
