#!/usr/bin/env bash
#
# forensics.sh — Digital forensics toolkit
# Run as your NORMAL user, inside Arch, AFTER arch-setup.sh.
#   chmod +x forensics.sh && ./forensics.sh
# -----------------------------------------------------------------------------
set -uo pipefail
G='\033[1;32m'; Y='\033[1;33m'; N='\033[0m'
ok(){ echo -e "${G}  [done]${N} $1"; }; warn(){ echo -e "${Y}  [skip]${N} $1"; }
[[ $EUID -eq 0 ]] && { echo "Run as normal user, not root."; exit 1; }
pac(){ sudo pacman -S --needed --noconfirm "$@"; }
tryget(){ sudo pacman -S --needed --noconfirm "$1" 2>/dev/null || yay -S --needed --noconfirm "$1" 2>/dev/null || warn "$1"; }

echo "==> Installing digital forensics tools"
# disk / filesystem / recovery
pac sleuthkit testdisk ddrescue dcfldd
# artifacts / metadata / carving
pac perl-image-exiftool
tryget foremost; tryget scalpel; tryget bulk_extractor
# memory forensics
pac python-pipx
pipx install volatility3 2>/dev/null && ok "volatility3 (vol) installed" || warn "volatility3"
# network / pcap
pac wireshark-qt tcpdump termshark 2>/dev/null || pac wireshark-qt tcpdump
# triage / misc
tryget autopsy
sudo usermod -aG wireshark "$USER" 2>/dev/null || true

echo
ok "forensics toolkit ready"
echo "   memory analysis:  vol -f dump.raw windows.info"
echo "   disk analysis:    mmls / fls / icat (sleuthkit) ,  testdisk ,  photorec"
echo "   carving:          foremost -i file.img -o out/ ,  bulk_extractor"
echo "   (re-login once for the wireshark group)"
