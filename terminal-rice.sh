#!/usr/bin/env bash
#
# terminal-rice.sh — Pretty terminal: character image + system info + theme
# Run as your NORMAL user AFTER arch-setup.sh, inside your Arch system.
#
#   chmod +x terminal-rice.sh
#   ./terminal-rice.sh
#
# Then drop YOUR character image at:  ~/.config/fastfetch/logo.png
# (png or jpg — any size, it gets scaled automatically)
# -----------------------------------------------------------------------------

set -uo pipefail
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "\n${C}==>${N} $1"; }; ok(){ echo -e "${G}  [done]${N} $1"; }
warn(){ echo -e "${Y}  [skip]${N} $1"; }

[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }

pac(){ sudo pacman -S --needed --noconfirm "$@"; }

# ---- packages ---------------------------------------------------------------
log "Installing fastfetch, kitty, chafa + extras"
pac fastfetch kitty chafa imagemagick figlet
pac lolcat 2>/dev/null || warn "lolcat not in repos (optional)"
ok "packages ready"

# ---- kitty terminal: theme + font (best image quality) ----------------------
log "Configuring kitty (Catppuccin Mocha theme)"
mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
font_family      JetBrainsMono Nerd Font
font_size        12.0
cursor_shape     beam
background_opacity 0.95
confirm_os_window_close 0
enable_audio_bell no
window_padding_width 8
# --- Catppuccin Mocha ---
foreground            #cdd6f4
background            #1e1e2e
selection_foreground  #1e1e2e
selection_background  #f5e0dc
cursor                #f5e0dc
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
EOF
ok "kitty themed"

# ---- fastfetch: show character image + specs --------------------------------
log "Configuring fastfetch with character logo"
mkdir -p "$HOME/.config/fastfetch"
cat > "$HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    // YOUR image goes here. kitty = crisp; change to "chafa" for Konsole/others.
    "source": "~/.config/fastfetch/logo.png",
    "type": "kitty",
    "width": 32,
    "padding": { "top": 1, "right": 3 }
  },
  "display": { "separator": "  " },
  "modules": [
    "title",
    "separator",
    { "type": "os",        "key": "  OS",     "keyColor": "blue"    },
    { "type": "kernel",    "key": "  Kernel", "keyColor": "blue"    },
    { "type": "uptime",    "key": "  Uptime", "keyColor": "magenta" },
    { "type": "packages",  "key": "  Pkgs",   "keyColor": "magenta" },
    { "type": "shell",     "key": "  Shell",  "keyColor": "green"   },
    { "type": "de",        "key": "  DE",     "keyColor": "green"   },
    { "type": "terminal",  "key": "  Term",   "keyColor": "cyan"    },
    { "type": "cpu",       "key": "  CPU",    "keyColor": "yellow"  },
    { "type": "gpu",       "key": "  GPU",    "keyColor": "yellow"  },
    { "type": "memory",    "key": "  RAM",    "keyColor": "red"     },
    "break",
    "colors"
  ]
}
EOF
ok "fastfetch configured"

# ---- placeholder image so it doesn't error before you add yours -------------
if [[ ! -f "$HOME/.config/fastfetch/logo.png" ]]; then
  magick -size 400x400 xc:'#1e1e2e' \
    -gravity center -pointsize 40 -fill '#89b4fa' \
    -annotate 0 'DROP\nYOUR\nIMAGE\nHERE' \
    "$HOME/.config/fastfetch/logo.png" 2>/dev/null && \
    ok "placeholder image created" || warn "placeholder skipped"
fi

# ---- run fastfetch on every new terminal ------------------------------------
log "Hooking fastfetch into shell startup"
RC="$HOME/.zshrc"; [[ -f "$RC" ]] || RC="$HOME/.bashrc"
if ! grep -q 'fastfetch  # rice' "$RC" 2>/dev/null; then
  cat >> "$RC" <<'EOF'

# show character + system info on launch
command -v fastfetch >/dev/null && fastfetch  # rice
EOF
  ok "added to $RC"
else ok "already hooked"; fi

echo -e "\n${G}============================================================${N}"
echo -e "${G} Terminal rice done.${N}"
echo -e " 1) Save your character image as:"
echo -e "      ${C}~/.config/fastfetch/logo.png${N}"
echo -e " 2) Open ${C}kitty${N} (best quality) and you'll see it."
echo -e " 3) In Konsole? edit config.jsonc: change ${C}\"type\": \"kitty\"${N} -> ${C}\"chafa\"${N}"
echo -e " Make kitty your default: System Settings > Default Applications > Terminal"
echo -e "${G}============================================================${N}"
