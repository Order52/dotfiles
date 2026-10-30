#!/bin/bash
# One-click installer: desktop, dotfiles, kernel driver, fan control, tuning, services. Safe to re-run.
#
#   ./install.sh                 everything (asks for sudo once)
#   ./install.sh --no-packages   skip package installation
#   ./install.sh --user-only     only copy dotfiles/scripts into $HOME (no sudo, no system changes)
#   ./install.sh --dry-run       show what would happen, change nothing
#   ./install.sh --yes           don't ask for confirmation
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
REPO=$PWD

PACKAGES=1 SYSTEM=1 DRY=0 ASSUME_YES=0
for a in "$@"; do
  case "$a" in
    --no-packages) PACKAGES=0 ;;
    --user-only)   PACKAGES=0; SYSTEM=0 ;;
    --dry-run)     DRY=1 ;;
    -y|--yes)      ASSUME_YES=1 ;;
    -h|--help)     sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user (sudo is used where needed), not as root."; exit 1; }

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

cat <<EOF
This will set up the full desktop on this machine (user: $USER):
  1. install packages ........ $([ $PACKAGES = 1 ] && echo yes || echo skipped)
  2. copy dotfiles, plugins, scripts into $HOME (existing files are backed up first)
  3. system setup (sudo) ..... $([ $SYSTEM = 1 ] && echo "driver (DKMS), fan service, tuning, sleep fixes, hooks" || echo skipped)
EOF
if [ "$ASSUME_YES" = 0 ] && [ "$DRY" = 0 ]; then read -rp "Continue? [y/N] " ok; [[ "$ok" =~ ^[Yy] ]] || exit 0; fi
[ "$SYSTEM" = 1 ] && [ "$DRY" = 0 ] && sudo -v

# ---------------------------------------------------------------- 1. packages
if [ "$PACKAGES" = 1 ]; then
  say "Official packages"
  run sudo pacman -S --needed --noconfirm - < packages-official.txt || echo "  (some packages failed - continuing)"
  say "AUR packages"
  if command -v paru >/dev/null; then H=paru; elif command -v yay >/dev/null; then H=yay; else H=""; fi
  if [ -n "$H" ]; then run $H -S --needed --noconfirm - < packages-aur.txt || echo "  (some AUR packages failed - continuing)"
  else echo "  no AUR helper found; install these yourself:"; sed 's/^/    /' packages-aur.txt; fi
fi

# ---------------------------------------------------------------- 2. user files
say "Backing up existing configs"
BACKUP=$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)
run mkdir -p "$BACKUP"
for d in config/*; do n=$(basename "$d"); [ -e "$HOME/.config/$n" ] && run cp -a "$HOME/.config/$n" "$BACKUP/" 2>/dev/null || true; done
for f in shell/.[!.]*; do n=$(basename "$f"); [ -e "$HOME/$n" ] && run cp -a "$HOME/$n" "$BACKUP/" || true; done

say "Installing dotfiles"
run mkdir -p "$HOME/.scripts/Acer/PredatorSense" "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/noctalia/plugins" "$HOME/.scripts" "$HOME/.config/systemd/user"
run rsync -a config/ "$HOME/.config/"
run rsync -a local-share/noctalia-plugins/ "$HOME/.local/share/noctalia/plugins/"
run rsync -a local-bin/ "$HOME/.local/bin/"
run chmod +x "$HOME"/.local/bin/*.py "$HOME"/.local/bin/*.sh 2>/dev/null || true
run rsync -a scripts/ "$HOME/.scripts/"
run rsync -a third-party/ "$HOME/.scripts/Acer/PredatorSense/"
for f in shell/.[!.]*; do run cp "$f" "$HOME/$(basename "$f")"; done
run rsync -a kde/color-schemes/ "$HOME/.local/share/color-schemes/" 2>/dev/null || true
run rsync -a kde/konsole/ "$HOME/.local/share/konsole/" 2>/dev/null || true
for f in kde/*; do [ -f "$f" ] && run cp "$f" "$HOME/.config/$(basename "$f")"; done

if command -v pipx >/dev/null; then
  say "Keyboard RGB tool (rgbkb)"
  run pipx install --force "$REPO/third-party/rgbkb/ph16-71-rgb" >/dev/null 2>&1 && echo "  rgbkb installed; try:  kbd-rgb" || echo "  (pipx install failed - run: pipx install third-party/rgbkb/ph16-71-rgb)"
else
  echo "  pipx not found: install python-pipx, then  pipx install third-party/rgbkb/ph16-71-rgb  (keyboard RGB)"
fi

# the configs were written for user "sloppy"
if [ "$HOME" != /home/sloppy ] && [ "$DRY" = 0 ]; then
  say "Rewriting /home/sloppy -> $HOME in copied configs"
  targets=()
  for d in config/*; do targets+=("$HOME/.config/$(basename "$d")"); done
  for f in kde/*; do [ -f "$f" ] && targets+=("$HOME/.config/$(basename "$f")"); done
  for f in shell/.[!.]*; do targets+=("$HOME/$(basename "$f")"); done
  targets+=("$HOME/.local/share/noctalia" "$HOME/.local/bin" "$HOME/.scripts")
  grep -rIl "/home/sloppy" "${targets[@]}" 2>/dev/null | xargs -r sed -i "s|/home/sloppy|$HOME|g"
fi

# ---------------------------------------------------------------- 3. system
if [ "$SYSTEM" = 1 ]; then
  say "System setup (sudo)"
  if [ "$DRY" = 1 ]; then echo "  [dry-run] sudo bash setup/system.sh $USER $REPO"
  else sudo bash setup/system.sh "$USER" "$REPO"; fi
fi

say "Done"
cat <<'EOF'
  * Log out and back in (or restart Hyprland) to load the desktop.
  * Put wallpapers in ~/Pictures/Wallpapers (the repo does not ship images).
  * Check the fan/thermal service:   systemctl status predator    and   cat /tmp/predator-state
  * Self-test (needs sudo):          sudo bash tools/test-predator.sh
EOF
