#!/bin/bash
# Restore this setup on a fresh CachyOS/Arch install.   Usage:  ./install.sh [--packages] [--system]
#   (no flag) copy user dotfiles into $HOME     --packages  also install the package lists     --system  also install system files (sudo)
set -e
cd "$(dirname "$0")"
backup=~/dotfiles-backup-$(date +%Y%m%d-%H%M%S)

echo "Backing up existing configs to $backup"
mkdir -p "$backup"
for d in config/*; do n=$(basename "$d"); [ -e ~/.config/$n ] && cp -a ~/.config/$n "$backup/" 2>/dev/null || true; done

echo "Installing user dotfiles"
mkdir -p ~/.config ~/.local/share/noctalia/plugins ~/.local/bin ~/.scripts
rsync -a config/ ~/.config/
rsync -a local-share/noctalia-plugins/ ~/.local/share/noctalia/plugins/
install -m 755 local-bin/predator-daemon.py ~/.local/bin/
rsync -a scripts/ ~/.scripts/

for a in "$@"; do
  case "$a" in
    --packages)
      sudo pacman -S --needed - < packages-official.txt
      echo "AUR packages (install with your helper):"; cat packages-aur.txt ;;
    --system)
      echo "Installing system files (sudo)"
      sudo rsync -a --exclude='etc/default/limine' --exclude='etc/lact' system/ /
      sudo install -d /etc/lact && sudo cp -n system/etc/lact/config.yaml /etc/lact/config.yaml
      echo "Then run, in order:  sudo bash root-scripts/fix-profile.sh  root-scripts/tune-prep.sh  root-scripts/install-predator.sh  root-scripts/harden-module.sh"
      echo "(the linuwu_sense DKMS driver source must be installed first: https://github.com/0x7375646F/Linuwu-Sense)" ;;
  esac
done
echo "Done. Log out and back in (or restart Hyprland)."
