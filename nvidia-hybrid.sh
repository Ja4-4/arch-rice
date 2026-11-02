#!/usr/bin/env bash
#
# nvidia-hybrid.sh — Intel + NVIDIA RTX 3050 (Optimus) setup for MSI laptop
# Run as your NORMAL user, AFTER arch-setup.sh, inside your Arch system.
#
#   chmod +x nvidia-hybrid.sh
#   ./nvidia-hybrid.sh
#   sudo reboot
#
# Setup: Intel iGPU drives the laptop screen (saves battery).
#        NVIDIA runs on-demand via `prime-run <app>` (games, CUDA, HDMI output).
# Uses nvidia-dkms so it survives ANY kernel update automatically.
# -----------------------------------------------------------------------------

set -uo pipefail
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "\n${C}==>${N} $1"; }; ok(){ echo -e "${G}  [done]${N} $1"; }
warn(){ echo -e "${Y}  [warn]${N} $1"; }
[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }
pac(){ sudo pacman -S --needed --noconfirm "$@"; }

# ---- kernel headers (for dkms) ----------------------------------------------
log "Installing kernel headers for installed kernels"
HEADERS=()
pacman -Q linux        &>/dev/null && HEADERS+=(linux-headers)
pacman -Q linux-lts    &>/dev/null && HEADERS+=(linux-lts-headers)
pacman -Q linux-zen    &>/dev/null && HEADERS+=(linux-zen-headers)
[[ ${#HEADERS[@]} -eq 0 ]] && HEADERS+=(linux-headers)
pac "${HEADERS[@]}"
ok "headers: ${HEADERS[*]}"

# ---- Intel graphics stack ---------------------------------------------------
log "Installing Intel iGPU drivers"
pac mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver \
    vulkan-icd-loader lib32-vulkan-icd-loader
ok "Intel ready"

# ---- NVIDIA (dkms) + PRIME offload ------------------------------------------
log "Installing NVIDIA RTX 3050 drivers (dkms)"
pac nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings nvidia-prime \
    opencl-nvidia lib32-opencl-nvidia
ok "NVIDIA ready"

# ---- enable DRM modesetting (needed for Wayland / clean boot) ---------------
log "Setting nvidia_drm.modeset=1 kernel parameter"
GRUBF=/etc/default/grub
if ! grep -q 'nvidia_drm.modeset=1' "$GRUBF"; then
  sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia_drm.modeset=1"/' "$GRUBF"
  ok "kernel param added"
else ok "param already set"; fi

# ---- make sure Windows shows in the GRUB menu (dual-boot) -------------------
log "Enabling os-prober so Windows appears in GRUB"
pac os-prober
if ! grep -q '^GRUB_DISABLE_OS_PROBER=false' "$GRUBF"; then
  echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$GRUBF" >/dev/null
fi
ok "os-prober on"

# ---- add nvidia modules to initramfs ----------------------------------------
log "Adding NVIDIA modules to mkinitcpio"
MKC=/etc/mkinitcpio.conf
if ! grep -q 'nvidia_drm' "$MKC"; then
  sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKC"
  # clean up a possible leading space if MODULES was empty
  sudo sed -i 's/^MODULES=( /MODULES=(/' "$MKC"
  ok "modules added"
else ok "modules already present"; fi

# ---- rebuild initramfs + grub config ----------------------------------------
log "Rebuilding initramfs"
sudo mkinitcpio -P && ok "initramfs rebuilt" || warn "mkinitcpio had issues — check output"

log "Regenerating GRUB config (detects Windows + applies params)"
sudo grub-mkconfig -o /boot/grub/grub.cfg && ok "grub updated" || warn "grub-mkconfig issue"

echo -e "\n${G}============================================================${N}"
echo -e "${G} NVIDIA hybrid setup complete.${N}"
echo -e "   ${C}sudo reboot${N}"
echo
echo -e " Daily use:"
echo -e "   - Laptop screen runs on Intel automatically (good battery)."
echo -e "   - Run heavy apps on the RTX 3050 with:  ${C}prime-run <app>${N}"
echo -e "       e.g.  ${C}prime-run glxgears${N}   or   ${C}prime-run steam${N}"
echo -e "   - Check it works:   ${C}prime-run nvidia-smi${N}"
echo
echo -e " If the KDE login looks glitchy on first boot, pick"
echo -e "   ${C}Plasma (X11)${N} at the login screen (gear icon)."
echo -e "${G}============================================================${N}"
