#!/usr/bin/env bash
#
# arch-setup.sh — Post-install customization for a security researcher / dev
# Run this as your NORMAL user (NOT root) after a fresh `archinstall` + first boot.
#
#   chmod +x arch-setup.sh
#   ./arch-setup.sh
#
# Safe to re-run: installs skip what's already there.
# -----------------------------------------------------------------------------

set -uo pipefail

###############################################################################
# TOGGLES — set to 1 (on) or 0 (off). DESKTOP = kde | hyprland | none
###############################################################################
DESKTOP="kde"
INSTALL_DEV=1          # python, c/c++, node, git, editors, debuggers
INSTALL_SECURITY=1     # pentest / CTF / bug-bounty arsenal
INSTALL_SHELL=1        # zsh + starship prompt + nerd fonts
INSTALL_ARABIC=1       # Arabic fonts + rendering
INSTALL_EXTRAS=1       # browser, media, daily apps
ENABLE_BLACKARCH=0     # add full BlackArch repo (~2800 tools, big). 1 = yes
###############################################################################

C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; N='\033[0m'
log()  { echo -e "\n${C}==>${N} ${1}"; }
ok()   { echo -e "${G}  [done]${N} ${1}"; }
warn() { echo -e "${Y}  [skip/warn]${N} ${1}"; }

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user, not root. The script uses sudo when needed."; exit 1
fi

# ---- helpers ----------------------------------------------------------------
pac()  { sudo pacman -S --needed --noconfirm "$@" ; }
aur()  { yay -S --needed --noconfirm "$@" ; }

# -----------------------------------------------------------------------------
log "Refreshing keyring, mirrors and system"
sudo pacman -Sy --noconfirm archlinux-keyring || true
pac reflector
sudo reflector --country 'Saudi Arabia,Bahrain,United Arab Emirates,Germany' \
  --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || \
  warn "reflector failed, keeping current mirrors"
sudo pacman -Syu --noconfirm
ok "system updated"

# ---- enable multilib (32-bit) -----------------------------------------------
log "Enabling multilib repo"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
  ok "multilib enabled"
else ok "multilib already on"; fi

# ---- base tools + yay (AUR helper) ------------------------------------------
log "Installing base-devel + yay"
pac base-devel git wget curl unzip less man-db
if ! command -v yay &>/dev/null; then
  tmp=$(mktemp -d); git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay"
  ( cd "$tmp/yay" && makepkg -si --noconfirm ); rm -rf "$tmp"
  ok "yay installed"
else ok "yay already installed"; fi

# =============================================================================
# DEVELOPMENT
# =============================================================================
if [[ $INSTALL_DEV -eq 1 ]]; then
  log "Development toolchain"
  pac python python-pip python-pipx \
      gcc clang llvm lld cmake make gdb lldb valgrind \
      nodejs npm \
      neovim tmux ripgrep fd fzf bat eza jq \
      docker docker-compose
  sudo systemctl enable --now docker.service || true
  sudo usermod -aG docker "$USER" || true
  pipx ensurepath || true
  aur visual-studio-code-bin || warn "VS Code (AUR) skipped"
  ok "dev tools ready (re-login for docker group)"
fi

# =============================================================================
# SECURITY / CTF / BUG BOUNTY
# =============================================================================
if [[ $INSTALL_SECURITY -eq 1 ]]; then
  log "Security arsenal (official repos)"
  pac nmap wireshark-qt tcpdump net-tools bind whois \
      john hashcat hydra aircrack-ng \
      sqlmap nikto \
      radare2 binwalk foremost \
      openbsd-netcat socat \
      exploitdb || warn "some official security pkgs skipped"
  sudo usermod -aG wireshark "$USER" || true

  log "Security arsenal (AUR)"
  aur burpsuite ffuf gobuster feroxbuster dirsearch \
      ghidra-bin \
      seclists || warn "some AUR security pkgs skipped"

  log "Python pwn/CTF libs (pipx, isolated)"
  pipx install pwntools   || warn "pwntools skipped"
  pipx install ropper     || warn "ropper skipped"

  if [[ $ENABLE_BLACKARCH -eq 1 ]]; then
    log "Adding BlackArch repo"
    tmp=$(mktemp -d); curl -fsSL https://blackarch.org/strap.sh -o "$tmp/strap.sh"
    echo "  (verify the sha1 at https://blackarch.org/downloads.html before trusting)"
    chmod +x "$tmp/strap.sh"; sudo "$tmp/strap.sh"; rm -rf "$tmp"
    sudo pacman -Syu --noconfirm
    ok "BlackArch enabled — install tools with: sudo pacman -S <tool>"
  fi
  ok "security tools ready (re-login for wireshark group)"
fi

# =============================================================================
# SHELL + FONTS
# =============================================================================
if [[ $INSTALL_SHELL -eq 1 ]]; then
  log "zsh + starship + nerd fonts"
  pac zsh starship ttf-jetbrains-mono-nerd ttf-firacode-nerd
  if [[ "$SHELL" != *zsh ]]; then chsh -s "$(command -v zsh)" || warn "chsh skipped"; fi
  grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null || \
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
  # quick-win aliases
  cat >> "$HOME/.zshrc" <<'EOF'

# --- custom aliases ---
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias vim='nvim'
EOF
  ok "shell configured (opens as zsh next login)"
fi

# =============================================================================
# ARABIC SUPPORT
# =============================================================================
if [[ $INSTALL_ARABIC -eq 1 ]]; then
  log "Arabic fonts & rendering"
  pac noto-fonts noto-fonts-emoji ttf-amiri
  aur ttf-sil-scheherazade || warn "Scheherazade skipped"
  ok "Arabic text will render properly"
fi

# =============================================================================
# EXTRAS
# =============================================================================
if [[ $INSTALL_EXTRAS -eq 1 ]]; then
  log "Daily apps"
  pac firefox mpv vlc obs-studio keepassxc flameshot
  aur brave-bin || warn "brave skipped"
  ok "extras installed"
fi

# =============================================================================
# DESKTOP ENVIRONMENT
# =============================================================================
case "$DESKTOP" in
  kde)
    log "Installing KDE Plasma + SDDM"
    pac plasma-meta sddm konsole dolphin kate ark spectacle \
        plasma-nm pipewire pipewire-pulse wireplumber
    sudo systemctl enable sddm.service
    ok "KDE Plasma ready — reboot to log in graphically"
    ;;
  hyprland)
    log "Installing Hyprland + essentials"
    pac hyprland sddm kitty waybar wofi dolphin \
        xdg-desktop-portal-hyprland \
        pipewire pipewire-pulse wireplumber \
        grim slurp mako hyprpaper polkit-kde-agent
    sudo systemctl enable sddm.service
    ok "Hyprland ready — you'll want to drop a config in ~/.config/hypr/"
    ;;
  none) warn "No desktop selected (DESKTOP=none)";;
  *)    warn "Unknown DESKTOP='$DESKTOP'";;
esac

echo -e "\n${G}============================================================${N}"
echo -e "${G} Setup complete.${N}"
echo -e " Reboot now:  ${C}sudo reboot${N}"
echo -e " After reboot you'll get a graphical login (${DESKTOP})."
echo -e "${G}============================================================${N}"
