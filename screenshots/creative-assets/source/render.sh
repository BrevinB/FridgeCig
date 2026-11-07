#!/bin/bash
# usage: render.sh name W H [debug]
cd "$(dirname "$0")"
url="file://$PWD/$1.html"; [ -n "$4" ] && url="$url#debug"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1 --window-size=$2,$3 --allow-file-access-from-files \
  --virtual-time-budget=3000 --screenshot="$PWD/$1${4:+-debug}.png" "$url" >/dev/null 2>&1
echo "$1${4:+-debug}.png"
