#!/usr/bin/env bash
#
# add-image.sh — install any image as a theme's wallpaper or character logo
# Run inside Arch, after rice-install.sh.
#
#   ./add-image.sh <theme> <image> [wall|logo]
#
# examples:
#   ./add-image.sh dexter  ~/Downloads/dexter.jpg   wall
#   ./add-image.sh jarvis  ~/Downloads/tony.png     logo
#
# themes: jarvis | cyberpunk | mrrobot | dexter
# It auto-resizes and, if that theme is active, applies it immediately.
# -----------------------------------------------------------------------------
set -uo pipefail
T="${1:-}"; SRC="${2:-}"; KIND="${3:-wall}"
cfg="$HOME/.config/rice"

case "$T" in jarvis|cyberpunk|mrrobot|dexter) ;; *)
  echo "usage: $0 <jarvis|cyberpunk|mrrobot|dexter> <image> [wall|logo]"; exit 1;; esac
[ -f "$SRC" ] || { echo "image not found: $SRC"; exit 1; }
command -v magick >/dev/null || { echo "imagemagick missing (it's installed by rice-install.sh)"; exit 1; }

if [ "$KIND" = "logo" ]; then
  mkdir -p "$cfg/logos"
  magick "$SRC" -resize 400x400 "$cfg/logos/$T.png"
  echo "character logo set for '$T'"
else
  mkdir -p "$cfg/walls"
  magick "$SRC" -resize 1920x1080^ -gravity center -extent 1920x1080 "$cfg/walls/$T.jpg"
  echo "wallpaper set for '$T'"
fi

# apply instantly if that theme is the active one
if [ "$(cat "$cfg/current" 2>/dev/null)" = "$T" ]; then
  "$cfg/apply-theme.sh" "$T" >/dev/null 2>&1 && echo "applied now."
else
  echo "switch to it with:  theme $T"
fi
