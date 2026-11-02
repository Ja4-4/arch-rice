#!/usr/bin/env bash
#
# rice-install.sh — Hyprland cyber-rice with a 4-theme switcher
#   Themes: jarvis | cyberpunk | mrrobot | dexter
#   Base:   dark, glassy (blur + transparency), neon glow  (Y2K / cyberpunk)
#
# Run as your NORMAL user, AFTER arch-setup.sh + nvidia-hybrid.sh, inside Arch.
#   chmod +x rice-install.sh && ./rice-install.sh
#
# After it finishes: log out, pick the "Hyprland" session at the login screen.
#   Super+Return = terminal   Super+Space = app launcher   Super+T = switch theme
#
# Put YOUR images (not downloaded for you — copyright) here, named by theme:
#   Wallpapers:  ~/.config/rice/walls/jarvis.jpg  (also cyberpunk/mrrobot/dexter)
#   Characters:  ~/.config/rice/logos/jarvis.png  (shown in terminal by fastfetch)
# -----------------------------------------------------------------------------

set -uo pipefail
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "\n${C}==>${N} $1"; }; ok(){ echo -e "${G}  [done]${N} $1"; }
warn(){ echo -e "${Y}  [skip]${N} $1"; }
[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }
pac(){ sudo pacman -S --needed --noconfirm "$@"; }
aur(){ yay -S --needed --noconfirm "$@"; }
tryget(){ sudo pacman -S --needed --noconfirm "$1" 2>/dev/null || yay -S --needed --noconfirm "$1" 2>/dev/null || warn "$1"; }

# ---- packages ---------------------------------------------------------------
log "Installing Hyprland + ecosystem"
pac hyprland waybar wofi kitty mako libnotify hyprlock hypridle \
    grim slurp wl-clipboard cliphist \
    brightnessctl pamixer playerctl polkit-kde-agent \
    network-manager-applet qt5-wayland qt6-wayland \
    xdg-desktop-portal-hyprland \
    fastfetch chafa imagemagick btop jq \
    ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts noto-fonts-emoji
log "Installing eye-candy tools"
tryget swww; tryget cava; tryget cmatrix; tryget lolcat; tryget figlet
tryget pipes.sh; tryget hollywood
ok "packages done"

cfg="$HOME/.config"
mkdir -p "$cfg/hypr" "$cfg/waybar" "$cfg/wofi" "$cfg/kitty" "$cfg/fastfetch" \
         "$cfg/rice/walls" "$cfg/rice/logos"

# =============================================================================
# Hyprland main config  (colors live in colors.conf, rewritten per theme)
# =============================================================================
log "Writing Hyprland config"
cat > "$cfg/hypr/hyprland.conf" <<'HYPREOF'
monitor=,preferred,auto,1
source = ~/.config/hypr/colors.conf

$terminal = kitty
$menu = wofi --show drun
$fileManager = dolphin
$mod = SUPER

env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland

exec-once = swww-daemon
exec-once = mako
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = wl-paste --watch cliphist store
exec-once = sleep 1 && ~/.config/rice/apply-theme.sh "$(cat ~/.config/rice/current 2>/dev/null || echo jarvis)"

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = $accent $accent2 45deg
    col.inactive_border = $inactive
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 12
    active_opacity = 0.94
    inactive_opacity = 0.86
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
    }
    shadow {
        enabled = true
        range = 24
        render_power = 3
        color = $accent
    }
}

animations {
    enabled = true
    bezier = smooth, 0.25, 0.1, 0.25, 1
    animation = windows, 1, 5, smooth, slide
    animation = windowsOut, 1, 5, smooth, slide
    animation = fade, 1, 7, smooth
    animation = workspaces, 1, 6, smooth, slide
    animation = border, 1, 10, smooth
}

dwindle { pseudotile = true; preserve_split = true }
cursor { no_hardware_cursors = true }

input {
    kb_layout = us,ar
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad { natural_scroll = true }
}

# --- keybinds ---
bind = $mod, Return, exec, $terminal
bind = $mod, Q, killactive
bind = $mod, M, exit
bind = $mod, E, exec, $fileManager
bind = $mod, Space, exec, $menu
bind = $mod, F, fullscreen
bind = $mod, V, togglefloating
bind = $mod, L, exec, hyprlock
bind = $mod, T, exec, ~/.config/rice/theme-menu.sh
bind = $mod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
bind = , Print, exec, grim - | wl-copy
bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
bindel = , XF86AudioMute, exec, pamixer -t
bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
HYPREOF
ok "hyprland.conf written"

# ---- hyprlock / hypridle (minimal) ------------------------------------------
cat > "$cfg/hypr/hyprlock.conf" <<'EOF'
background { color = rgba(0,0,0,1.0) }
input-field {
    size = 260, 54
    outline_thickness = 2
    dots_center = true
    placeholder_text = <i>Password...</i>
    position = 0, -20
    halign = center; valign = center
}
EOF
cat > "$cfg/hypr/hypridle.conf" <<'EOF'
general { lock_cmd = hyprlock; before_sleep_cmd = loginctl lock-session }
listener { timeout = 300; on-timeout = hyprlock }
listener { timeout = 600; on-timeout = systemctl suspend }
EOF

# =============================================================================
# Waybar config (static modules; colors come from style.css per theme)
# =============================================================================
log "Writing Waybar config"
cat > "$cfg/waybar/config.jsonc" <<'EOF'
{
  "layer": "top", "position": "top", "height": 34, "spacing": 4,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["cpu","memory","pulseaudio","network","battery","tray"],
  "hyprland/workspaces": { "format": "{icon}", "on-click": "activate" },
  "clock": { "format": "  {:%H:%M  %a %d %b}" },
  "cpu": { "format": "  {usage}%" },
  "memory": { "format": "  {percentage}%" },
  "pulseaudio": { "format": "  {volume}%", "format-muted": "  muted" },
  "network": { "format-wifi": "  {signalStrength}%", "format-ethernet": "  ", "format-disconnected": "  off" },
  "battery": { "format": "{icon}  {capacity}%", "format-icons": ["","","","",""] },
  "tray": { "spacing": 8 }
}
EOF
ok "waybar config written"

# =============================================================================
# kitty (opacity here; colors in current-theme.conf per theme)
# =============================================================================
log "Writing kitty config"
cat > "$cfg/kitty/kitty.conf" <<'EOF'
font_family      JetBrainsMono Nerd Font
font_size        12.0
cursor_shape     beam
background_opacity 0.90
window_padding_width 10
confirm_os_window_close 0
enable_audio_bell no
include current-theme.conf
EOF
ok "kitty config written"

# =============================================================================
# fastfetch (logo = current character symlink, rewritten per theme)
# =============================================================================
log "Writing fastfetch config"
cat > "$cfg/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": { "source": "~/.config/rice/logos/current", "type": "kitty", "width": 32, "padding": { "top": 1, "right": 3 } },
  "display": { "separator": "  " },
  "modules": [
    "title", "separator",
    { "type": "os", "key": "  OS", "keyColor": "cyan" },
    { "type": "kernel", "key": "  Kernel", "keyColor": "cyan" },
    { "type": "uptime", "key": "  Uptime", "keyColor": "magenta" },
    { "type": "packages", "key": "  Pkgs", "keyColor": "magenta" },
    { "type": "wm", "key": "  WM", "keyColor": "green" },
    { "type": "terminal", "key": "  Term", "keyColor": "green" },
    { "type": "cpu", "key": "  CPU", "keyColor": "yellow" },
    { "type": "gpu", "key": "  GPU", "keyColor": "yellow" },
    { "type": "memory", "key": "  RAM", "keyColor": "red" },
    "break", "colors"
  ]
}
EOF
ok "fastfetch config written"

# =============================================================================
# THEME ENGINE — apply-theme.sh repaints everything + swaps wallpaper/logo
# =============================================================================
log "Writing theme engine"
cat > "$cfg/rice/apply-theme.sh" <<'APPLY'
#!/usr/bin/env bash
# apply-theme.sh <jarvis|cyberpunk|mrrobot|dexter>
set -uo pipefail
T="${1:-jarvis}"; cfg="$HOME/.config"
case "$T" in
  jarvis)    BG=020a14; BG2=01111f; FG=c7f5ff; ACCENT=00d9ff; ACCENT2=ffb000; INACTIVE=0a2230;;
  cyberpunk) BG=0a0a12; BG2=0d0221; FG=d1f7ff; ACCENT=ff2a6d; ACCENT2=05d9e8; INACTIVE=24122e;;
  mrrobot)   BG=000000; BG2=0a0f0a; FG=00ff41; ACCENT=00ff41; ACCENT2=008f11; INACTIVE=0d1f0d;;
  dexter)    BG=0a0000; BG2=100404; FG=ffd7d7; ACCENT=e01e37; ACCENT2=6a040f; INACTIVE=2a0a0a;;
  *) echo "themes: jarvis cyberpunk mrrobot dexter"; exit 1;;
esac

# Hyprland colors (keep Hyprland's own $vars literal via \$)
cat > "$cfg/hypr/colors.conf" <<EOF
\$accent = rgb($ACCENT)
\$accent2 = rgb($ACCENT2)
\$inactive = rgb($INACTIVE)
EOF

# kitty palette
cat > "$cfg/kitty/current-theme.conf" <<EOF
foreground #$FG
background #$BG
cursor #$ACCENT
selection_background #$ACCENT
selection_foreground #$BG
color0 #$BG2
color1 #$ACCENT
color2 #$ACCENT2
color3 #$ACCENT2
color4 #$ACCENT
color5 #$ACCENT
color6 #$ACCENT2
color7 #$FG
color8 #$INACTIVE
color9 #$ACCENT
color10 #$ACCENT2
color11 #$ACCENT2
color12 #$ACCENT
color13 #$ACCENT
color14 #$ACCENT2
color15 #$FG
EOF

# waybar style (fixed glass base + theme accent)
cat > "$cfg/waybar/style.css" <<EOF
* { font-family: "JetBrainsMono Nerd Font"; font-size: 13px; min-height: 0; }
window#waybar { background: rgba(8,10,16,0.55); color: #$FG; }
#workspaces button { color: #$FG; padding: 0 8px; }
#workspaces button.active { color: #$BG; background: #$ACCENT; border-radius: 8px; }
#workspaces button:hover { color: #$ACCENT; }
#clock,#cpu,#memory,#network,#pulseaudio,#battery,#tray {
  padding: 0 10px; margin: 4px 2px; color: #$ACCENT;
  background: rgba(0,0,0,0.30); border: 1px solid #$ACCENT; border-radius: 10px;
}
#battery.charging { color: #$ACCENT2; border-color: #$ACCENT2; }
EOF

# wofi style
cat > "$cfg/wofi/style.css" <<EOF
window { background-color: rgba(8,10,16,0.85); border: 2px solid #$ACCENT; border-radius: 14px; font-family: "JetBrainsMono Nerd Font"; }
#input { margin: 10px; padding: 8px; border: none; border-radius: 10px; background: #$BG2; color: #$FG; }
#entry:selected { background: #$ACCENT; color: #$BG; border-radius: 10px; }
#text { color: #$FG; }
EOF
[ -f "$cfg/wofi/config" ] || printf 'allow_images=true\nimage_size=28\n' > "$cfg/wofi/config"

# wallpaper: user file beats generated gradient fallback
gen="$cfg/rice/walls/_gen_$T.png"
[ -f "$gen" ] || command -v magick >/dev/null && \
  magick -size 1920x1080 radial-gradient:"#$ACCENT"-"#$BG" "$gen" 2>/dev/null
wall="$gen"
for ext in jpg jpeg png; do u="$cfg/rice/walls/$T.$ext"; [ -f "$u" ] && wall="$u"; done
[ -f "$wall" ] && swww img "$wall" --transition-type grow --transition-pos center 2>/dev/null

# character logo for fastfetch
logo=""
for ext in png jpg jpeg; do u="$cfg/rice/logos/$T.$ext"; [ -f "$u" ] && logo="$u"; done
if [ -z "$logo" ]; then
  logo="$cfg/rice/logos/_gen_$T.png"
  [ -f "$logo" ] || command -v magick >/dev/null && \
    magick -size 400x400 radial-gradient:"#$ACCENT"-"#$BG2" -gravity center \
      -pointsize 34 -fill "#$FG" -annotate 0 "$T" "$logo" 2>/dev/null
fi
[ -f "$logo" ] && ln -sf "$logo" "$cfg/rice/logos/current"

echo "$T" > "$cfg/rice/current"

# live reload
hyprctl reload >/dev/null 2>&1 || true
pkill -SIGUSR1 kitty 2>/dev/null || true
pkill waybar 2>/dev/null; sleep 0.2; (waybar >/dev/null 2>&1 &)
command -v notify-send >/dev/null && notify-send " Theme" "Switched to: $T"
APPLY
chmod +x "$cfg/rice/apply-theme.sh"

# theme picker menu (Super+T)
cat > "$cfg/rice/theme-menu.sh" <<'EOF'
#!/usr/bin/env bash
c=$(printf 'jarvis\ncyberpunk\nmrrobot\ndexter' | wofi --dmenu --prompt "theme")
[ -n "$c" ] && ~/.config/rice/apply-theme.sh "$c"
EOF
chmod +x "$cfg/rice/theme-menu.sh"
ok "theme engine written"

# convenient `theme` command in PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$cfg/rice/apply-theme.sh" "$HOME/.local/bin/theme"

# ---- run fastfetch on terminal launch ---------------------------------------
RC="$HOME/.zshrc"; [[ -f "$RC" ]] || RC="$HOME/.bashrc"
grep -q 'fastfetch  # rice' "$RC" 2>/dev/null || \
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\ncommand -v fastfetch >/dev/null && fastfetch  # rice\n' >> "$RC"

# ---- set default theme + prebuild assets ------------------------------------
log "Applying default theme (jarvis)"
bash "$cfg/rice/apply-theme.sh" jarvis >/dev/null 2>&1 || true
# prebuild the other 3 gradient fallbacks so first switch is instant
for t in cyberpunk mrrobot dexter; do
  grep -q "$t)" "$cfg/rice/apply-theme.sh" && \
  ( cd "$cfg/rice" && bash "$cfg/rice/apply-theme.sh" "$t" >/dev/null 2>&1 ) || true
done
bash "$cfg/rice/apply-theme.sh" jarvis >/dev/null 2>&1 || true
ok "themes ready"

echo -e "\n${G}============================================================${N}"
echo -e "${G} Rice installed.${N}"
echo -e " 1) Log out  ->  pick ${C}Hyprland${N} session at the login screen."
echo -e " 2) Keybinds:  ${C}Super+Return${N} terminal   ${C}Super+Space${N} apps"
echo -e "               ${C}Super+T${N} switch theme     ${C}Super+Q${N} close window"
echo -e " 3) Switch theme from a terminal too:  ${C}theme cyberpunk${N}"
echo -e " 4) Drop YOUR images (named by theme):"
echo -e "      walls:  ${C}~/.config/rice/walls/<theme>.jpg${N}"
echo -e "      chars:  ${C}~/.config/rice/logos/<theme>.png${N}"
echo -e "    themes = jarvis / cyberpunk / mrrobot / dexter"
echo -e " KDE is still installed as a stable fallback session."
echo -e "${G}============================================================${N}"
