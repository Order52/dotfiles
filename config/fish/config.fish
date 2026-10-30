# =============================================================================
# Fish Shell Configuration
# =============================================================================

alias calc='qalc'
function Python-pc-vision
    cd "/mnt/sloppy_tux/U.O.T/University stuff/Third Class/Reports/Finished/ODT/U.O.T Project"
    source Abd/bin/activate.fish
end

# Load CachyOS configuration (if available)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

alias Tlp-per='echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct'
alias Mount-usb 'sudo mount -t ntfs-3g /dev/sda1 /mnt/acer'
alias nano='nvim'
alias Ascii='asciiquarium'
alias Weather='curl wttr.in/iraq'
# ollama
set -U fish_user_paths /mnt/sloppy_tux/Home/AI/bin $fish_user_paths
set -Ux OLLAMA_MODELS /mnt/sloppy_tux/Home/AI/models

# Add to ~/.config/fish/config.fish
function fix-heroic
    sudo rm -rf /opt/Heroic/resources/app.asar.unpacked/build/bin/x64/linux/legendary
    sudo ln -s /usr/bin/legendary /opt/Heroic/resources/app.asar.unpacked/build/bin/x64/linux/legendary
    echo "Heroic fixed!"
end

# Kill Open files on storage USB 
function force-umount
    # Check if an argument was provided
    if test -z "$argv[1]"
        echo "Error: Please specify a mount point."
        return 1
    end

    echo "Killing processes on $argv[1]..."
    sudo fuser -k -m "$argv[1]"

    echo "Unmounting $argv[1]..."
    sudo umount "$argv[1]"

    echo "Done."
end

# CAMERA
alias Webcam='ffplay /dev/video0'
# AI
#alias ai='env OLLAMA_MODELS=/mnt/sloppy_tux/Home/AI/models /mnt/sloppy_tux/Home/AI/bin/ollama serve & disown'
alias ai='ollama serve'
#alias ai='env LD_LIBRARY_PATH=/mnt/sloppy_tux/Home/AI/ollama/lib/ollama/cuda_v13:/mnt/sloppy_tux/Home/AI/ollama/lib/ollama/cuda_v12:$LD_LIBRARY_PATH ollama serve'

alias ai-vision-qwen-ai='ollama run qwen3-vl:235b-instruct-cloud'
alias ai-vision-minicpm='ollama run minicpm-v'
alias ai-deepseek='ollama run deepseek-r1:8b'
alias ai-llama3='ollama show llama3'
alias ai-qwen-talk='ollama run qwen2.5-coder:7b'
alias ai-qwen='ollama run qwen2.5-coder-nocode'
alias ai-mistral='ollama run mistral:7b'
alias ai-GPT='ollama run gpt-oss:latest'
alias ai-GPT-cloud='ollama run gpt-oss:120b-cloud'
alias ai-qwen-cloud='ollama run qwen3-coder:480b-cloud'
alias ai-kill='pkill "ollama serve"'
# =============================================================================
# MPD
# =============================================================================

set -x MPD_HOST 127.0.0.1
set -x MPD_PORT 6600

alias Xwayland='--enable-features=UseOzonePlatform --ozone-platform=wayland'

# =============================================================================
# RANDOM
# =============================================================================
alias Dublicate='hyprctl keyword monitor "HDMI-A-1,1920x1080@60,0x0,1,mirror,eDP-1"'

alias Fix-echo='~/.config/hypr/scripts/Fix-echo.sh'
alias Ps='pstree -u $USER -p'
alias Openboard-build='cd ~/builds/openboard; makepkg -f -ei'

function Timer
    clear
    set SECONDS 0
    while true
        set hours (math --scale 0 "$SECONDS / 3600")
        set mins (math --scale 0 "$SECONDS / 60 % 60")
        set secs (math --scale 0 "$SECONDS % 60")

        set_color --bold cyan
        printf "\rTime: "
        set_color yellow
        printf "%02d:%02d:%02d" $hours $mins $secs
        set_color normal

        sleep 1
        set SECONDS (math "$SECONDS + 1")
    end
end

alias sleep='systemctl suspend'
alias in='sudo pacman -S'
alias un='sudo pacman -Rns'
alias up='shelly'

alias Games='pacman -Ql bsd-games | grep /usr/bin/'
# GREP Shorts
alias g 'rg -i' # recursive + case-insensitive (rg is recursive by default)
alias gm 'rg -i -E' # multiple regex patterns, case-insensitive
alias gi 'rg -i --no-recurse' # case-insensitive, non-recursive
alias gr rg # recursive, case-sensitive
alias gv 'rg -v' # invert match
alias gc 'rg -c' # count matches
alias gl 'rg -n' # show line numbers
alias gp 'rg -n --text' # recursive, line numbers, treat binary as text

# Waybar
alias Waybar-gui='python3 ~/Templates/WaybarGUI/waybar-configurator-GUI/waybar_configurator.py'

# ###############################################################################
# --- My Custom Log Aliases ---
# ###############################################################################

# Show all coredumps (crashes)
alias crashlist='coredumpctl list'

# Show errors from the *previous* boot (good for checking why you crashed)
alias lastbooterrors='journalctl -p 3 -b -1'

# Show high-priority errors from the last hour
alias logerrors='journalctl -p 3 --since "1 hour ago"'

# Show the Wayland/Hyprland session crash log (the command you ran)
alias sessionlog='journalctl --since "30 min ago" | grep -Ei "session|login|logout|sddm|hyprland|wayland.*die|segfault|abrt"'

# System/session related logs
alias jlogin="journalctl --since '30 min ago' | grep -Ei 'session|login|logout|systemd-logind|sddm|lightdm|gdm'"
alias jway="journalctl --since '30 min ago' | grep -Ei 'wayland|xwayland|hyprland|sway|plasma|gnome|xfce'"
alias jcrash="journalctl -k --since '30 min ago' | grep -Ei 'segfault|killed process|oom'"
alias juser="journalctl --user --since '30 min ago' | grep -Ei 'plasma|hypr|kded|kwin|swaync'"
alias jfull="journalctl -xe --since '30 min ago'"

# Recent core dumps
alias jcore="coredumpctl list | tail -n 10"
alias jcoreinfo="coredumpctl info"

# Shortcut for full dump of last crash
alias jlastcore="coredumpctl info $(coredumpctl list | tail -n 1 | awk '{print $1}')"

# =============================================================================
# DLNA SETUP
# =============================================================================
# DLNA
#alias DLNA='gmediarender -f "Sloppy_Acer"'
function DLNA
    sudo iptables -A INPUT -p udp --dport 1900 -j ACCEPT
    sudo iptables -A INPUT -p udp --dport 5353 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 49152:65535 -j ACCEPT
    gmediarender -f Sloppy_Acer
end

# Alias to make Steam Runtime read-only (fix slow online launch)
alias umu-fix='chmod -R a-w ~/.local/share/umu/steamrt3'

# Alias to revert to original permissions (drwxr-xr-x)
alias umu-revert='chmod -R 755 ~/.local/share/umu/steamrt3'

# =============================================================================
# KERNEL MODULES
# =============================================================================

alias Watch-kernel='sudo dmesg -w'
# CAMERA
alias Cam-load='sudo modprobe uvcvideo'
alias Cam-unload='sudo modprobe -r uvcvideo'

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

# Pure prompt configuration
set pure_enable_single_line_prompt true
set fish_recall_exit_status 0

# GPU
#set -gx PATH $HOME/.local/bin $PATH

# Custom prompt function
function fish_prompt
    printf "\e[0;32m%s\e[0m@\e[0;94m%s\e[0m \e[0;36m%s\e[0m \$ " (whoami) (prompt_hostname) (prompt_pwd)
end

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Theme and UI settings
set -x GTK_THEME Breeze-Dark
set -x GTK_USE_PORTAL 1

# Python environment
if test -d "$HOME/.pyenv/bin"
    set -x PATH "$HOME/.pyenv/bin" $PATH
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
end

# LM Studio CLI
if test -d "$HOME/.lmstudio/bin"
    set -x PATH $PATH "$HOME/.lmstudio/bin"
end

# Initialize zoxide (if available)
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# =============================================================================
# BASIC ALIASES
# =============================================================================

# File system navigation and listing
alias cd='z' # Use zoxide for smart cd
alias c='clear' # Quick clear
alias ex='exit' # Quick exit

# Modern replacements for ls
if command -v eza >/dev/null 2>&1
    alias ls='eza --color=always --group-directories-first --icons'
    alias la='eza -a --color=always --group-directories-first --icons'
    alias ll='eza --color=always --group-directories-first --icons'
    alias lt='eza -aT --color=always --group-directories-first --icons'
    alias l.="eza -a | grep -e '^\.'"
    alias tree='eza -T --color=always --group-directories-first --icons'
end

# Text editor
if command -v nvim >/dev/null 2>&1
    alias vim='nvim'
end

alias Librewolf='/usr/lib/librewolf/librewolf'

# Wallpaper Engine
alias Wallpaper='~/.scripts/other/timed-wallpaper.sh'
# =============================================================================
# SYSTEM INFORMATION & MONITORING
# =============================================================================

# System information
alias neo='fastfetch --logo-type file --logo ~/.config/fastfetch/logos/birds-black.txt'
alias nv='nvidia-smi' # GPU monitoring
alias cpuinfo='cat /proc/cpuinfo'
alias cpumode='cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

# Network information
alias ipublic='curl ifconfig.me'
alias ipp="ip route | grep default"
alias mac="ifconfig"
alias packets="sudo tcpdump"
alias ifconfig='ip addr show'
alias ipconfig='nmcli device show'
alias arpa='ip neigh show'
alias ipcal='ipcalc'

# =============================================================================
# DAVINCI RESOLVE
# =============================================================================

function D-convert
    # Check if argument is provided
    if test (count $argv) -eq 0
        echo "Usage: D-convert <video_file>"
        echo "Converts MP4 to MOV or MOV to MP4 automatically"
        return 1
    end

    set input_file $argv[1]

    # Check if file exists
    if not test -f "$input_file"
        echo "Error: File '$input_file' not found"
        return 1
    end

    # Get file extension
    set extension (string split -r -m1 . "$input_file")[2]

    # Get filename without extension
    set filename (string split -r -m1 . "$input_file")[1]

    # Convert based on extension
    switch $extension
        case mp4
            # Convert MP4 to MOV for DaVinci Resolve (MJPEG - guaranteed compatibility)
            set output_file "$filename.mov"
            echo "Converting $input_file to $output_file (MJPEG for DaVinci)..."
            ffmpeg -i "$input_file" -c:v mjpeg -q:v 3 -c:a pcm_s16le -f mov "$output_file"

        case mov
            # Convert MOV to MP4 (H.264 - delivery format)
            set output_file "$filename.mp4"
            echo "Converting $input_file to $output_file (H.264 delivery format)..."
            ffmpeg -i "$input_file" -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 192k "$output_file"

        case '*'
            echo "Error: Unsupported file extension '$extension'"
            echo "Only MP4 and MOV files are supported"
            return 1
    end

    # Check if conversion was successful
    if test $status -eq 0
        echo "Conversion completed successfully: $output_file"
    else
        echo "Error: Conversion failed"
        return 1
    end
end

# =============================================================================
# SYSTEM MANAGEMENT
# =============================================================================

# Package management
#alias update-all='paru -Syu; flatpak update -y'

# nvim 
# In ~/.config/fish/config.fish
set -gx EDITOR nvim
set -gx VISUAL nvim
alias sudoedit 'sudo -e'

# OPEN YT-DLP-GUI 
alias cts='~/AppImages/ConvertTheSpire/AppRun'
# Power management
alias hib='sudo systemctl hibernate'
alias Power='sudo auto-cpufreq --force powersave'
alias Per='sudo auto-cpufreq --force performance'
alias Bal='sudo auto-cpufreq --force reset'
alias cpusave='sudo cpupower frequency-set -g powersave'
alias cpuper='sudo cpupower frequency-set -g performance'

# System services
alias Systemd-tui='sudo systemd-manager-tui'
alias Systemd-services='systemd-manager-tui'
alias Lkde='sudo systemctl start sddm'
alias rekde='systemctl --user restart plasma-plasmashell'

# Boot analysis
alias Last-boot='systemd-analyze; systemd-analyze blame; systemd-analyze critical-chain'

# =============================================================================
# BOOTLOADER CONFIGURATION
# =============================================================================

# Limine bootloader
alias Limine-cmd='sudo -e nvim /etc/default/limine'
alias Limine-refresh='sudo limine-mkinitcpio'
alias Limine-update='sudo limine-entry-tool --scan'
alias Limine='sudo nvim /boot/limine.conf'
alias Limine-snapshots='sudo limine-snapper-sync'

# SystemD-boot configuration
alias SystemD='sudo nvim /etc/sdboot-manage.conf'
alias Systemd-boot='sudo nvim /boot/systemd/loader/loader.conf'
alias Systemd-kernel='sudo nvim /boot/systemd/loader/entries/cachyos.conf'
alias SystemDapply='sudo sdboot-manage gen'

# =============================================================================
# HYPRLAND WINDOW MANAGER
# =============================================================================

alias Hypr-animations='nvim ~/.config/hypr/config/animations.lua'
alias Hypr-colors='nvim ~/.config/hypr/config/colors.lua'
alias Hypr-defaults='nvim ~/.config/hypr/config/defaults.lua'
alias Hypr-keybinds='nvim ~/.config/hypr/config/keybinds.lua'
alias Hypr-variables='nvim ~/.config/hypr/config/variables.lua'
alias Hypr-autostart='nvim ~/.config/hypr/config/autostart.lua'
alias Hypr-decorations='nvim ~/.config/hypr/config/decorations.lua'
alias Hypr-environment='nvim ~/.config/hypr/config/environment.lua'
alias Hypr-input='nvim ~/.config/hypr/config/input.lua'
#alias Hypr-monitor='nvim ~/.config/hypr/config/monitors.lua'
alias Hypr-monitor='nvim ~/.config/hypr/config/monitors.lua'
alias Hypr-user-config='nvim ~/.config/hypr/config/user-config.lua'
alias Hypr-windowrules='nvim ~/.config/hypr/config/windowrules.lua'
alias Hypr-main='nvim ~/.config/hypr/hyprland.lua'
# Waybar management
alias waybar-reload='pkill waybar && hyprctl dispatch exec waybar'

# =============================================================================
# AUDIO MANAGEMENT
# =============================================================================

# Audio profile switching
alias Head='pactl set-card-profile alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic HiFi\ \(HDMI1\,\ HDMI2\,\ HDMI3\,\ Headphones\,\ Mic1\,\ Mic2\); pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink'

alias Sp='pactl set-card-profile alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"; pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink'

# =============================================================================
# GAMING & ENTERTAINMENT
# =============================================================================

# Steam utilities
alias dol='XDG_MENU_PREFIX=plasma- kbuildsycoca6'
alias find-proton='~/.scripts/Other/find_proton.sh'
alias gpu-screen='gsr-ui'
alias killwine='pkill -f wine; wineserver -k'

# Gaming directories
# alias mpv='cd ~/.var/app/io.mpv.Mpv/config/mpv/'
alias riskofrain='cd ~/.local/share/Steam/steamapps/compatdata/2669881596/pfx/drive_c/users/Public/Documents/OnlineFix/'

# Waydroid
alias waydroids="sudo waydroid container start"

# =============================================================================
# DEVELOPMENT & UTILITIES
# =============================================================================

# File extraction
alias extract='unp'

# Subtitle download
alias sub='subliminal download -l en'
alias sub-ara='subliminal download -l ar'

# Network tools
alias tracert='mtr'
alias key-find='sudo libinput debug-events'

# Git shortcuts
alias gitup='git add . && git commit -m "Update configs" && git push'

# Configuration editing
alias edital='nvim ~/.config/fish/config.fish'
# alias editr='nvim ~/.config/ranger/rc.conf'
alias ranger='spf'

# =============================================================================
# HARDWARE-SPECIFIC: ACER PREDATOR
# =============================================================================

# RGB keyboard control
alias rgb='python3 ~/.scripts/rgb_menu.py'

# Shutdown
alias shut='systemctl poweroff'

# Predator Sense utilities
alias sense='python ~/.scripts/uwusense-python-menu.py'
alias sense2='~/.scripts/uwusense.sh'
alias pred='pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR ~/.scripts/Acer/PredatorSense/predator-blue/build/appPredatorBlue'

# Brightness control
alias lowb='echo 0 | sudo tee /sys/class/backlight/nvidia_wmi_ec_backlight/brightness'
alias highb='echo 1 | sudo tee /sys/class/backlight/nvidia_wmi_ec_backlight/brightness'

# GPU fixes
alias nvfix='sudo nvidia-smi -lgc 300,1800; sudo nvidia-smi -pm 1'

# =============================================================================
# GAMING CONTROLLER (DUALSENSE)
# =============================================================================

# DualSense LED and trigger control
alias psoff='dualsensectl player-leds 1; dualsensectl lightbar on; dualsensectl trigger right 0 0; dualsensectl trigger left 0 0'
alias pstr='dualsensectl trigger right weapon 3 7 6; dualsensectl trigger left feedback 4 6'
alias pstroff='dualsensectl trigger right 0 0; dualsensectl trigger left 0 0'
alias pson='dualsensectl player-leds 0; dualsensectl lightbar off; dualsensectl trigger right weapon 3 7 6; dualsensectl trigger left feedback 4 6'

# =============================================================================
# ANDROID DEVELOPMENT
# =============================================================================

alias aroot='adb shell /data/app/moe.shizuku.privileged.api-c5LkK2LBnbRD0Vx1tufsKw==/lib/arm64/libshizuku.so'
alias Aroot='adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh'
alias proot='adb shell pm grant --user 0 s1m.savertuner android.permission.WRITE_SECURE_SETTINGS'
alias Adb-dev-off='adb shell settings put global development_settings_enabled 0'
alias Adb-dev-on='adb shell settings put global development_settings_enabled 1'

# =============================================================================
# SYSTEM MAINTENANCE
# =============================================================================

# System Defualts 
alias System-defaults='nvim ~/.config/mimeapps.list'
# Preload service management
alias preloadon='sudo systemctl enable preload; sudo systemctl start preload'
alias preloadoff='sudo systemctl disable preload; sudo systemctl stop preload'

# Memory monitoring
alias leak='cat ~/.scripts/memory_usage.log'

# BTRFS maintenance
alias btrfs-full-balance='sudo btrfs balance start --full-balance -v /'

# Session management
alias logout-force='kill -9 -1'
alias logout='loginctl terminate-user $USER'

# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================

# Steam compatibility data viewer
function csteam
    set grey (echo -e "\x1b[38;5;248m")
    set cyan (echo -e "\x1b[38;5;45m")
    set white (echo -e "\x1b[38;5;252m")
    set yellow (echo -e "\x1b[38;5;226m")
    set reset (echo -e "\x1b[0m")

    for id in ~/.steam/steam/steamapps/compatdata/*
        echo "$grey-----------------------------$reset"
        echo "$cyan"(basename "$id")": $reset"

        grep -i software "$id/pfx/user.reg" | grep -v Microsoft | head -n5 | while read line
            echo "$white$line$reset"
        end

        echo "$yellow Location: $id $reset"
    end

    echo "$grey-----------------------------$reset"
end

# VNC viewer function
function vm
    if test (count $argv) -eq 0
        echo "Usage: vm <IP:PORT>"
        return 1
    end
    remote-viewer vnc://$argv[1]
end

# Network isolation functions
function app-off
    firejail --net=none $argv
end

function app-on
    command $argv
end

# DualSense touchpad control
function ds-touchpad-disable
    sudo sed -i 's/ENV{LIBINPUT_IGNORE_DEVICE}="0"/ENV{LIBINPUT_IGNORE_DEVICE}="1"/' /etc/udev/rules.d/99-dualsense-touchpad.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "DualSense touchpad disabled."
end

function ps-touchpad-enable
    sudo sed -i 's/ENV{LIBINPUT_IGNORE_DEVICE}="1"/ENV{LIBINPUT_IGNORE_DEVICE}="0"/' /etc/udev/rules.d/99-dualsense-touchpad.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "DualSense touchpad enabled."
end

# Fan curve control functions
function fan-gaming
    sudo python3 ~/.scripts/fan.py performance
    # sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve2.py --daemon
end

function fan-powersave
    sudo python3 ~/.scripts/fan.py powersave
    #sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve2.py --daemon
end

function fan-balance
    sudo python3 ~/.scripts/fan.py balanced
    #  sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve2.py --daemon
end

#function fan-quiet
#sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve2.py --profile quiet
#sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve2.py --daemon
#end

# Lutris art downloader
function covers
    set art_dir "/mnt/sloppy_tux/Home/Games/Lutris/.lutris-art-downloader"
    if test -d "$art_dir"
        source "$art_dir/myenv/bin/activate.fish"
        python3 "$art_dir/main.py"
    else
        echo "Lutris art downloader not found at $art_dir"
    end
end

# Network switching script
function eve-net
    if test -f ~/eve-net-switch.sh
        ~/eve-net-switch.sh
    else
        echo "Network switch script not found"
    end
end

# Apply configuration changes
function applyal
    source ~/.config/fish/config.fish
    echo "Fish configuration reloaded"
end

# =============================================================================
# PORTABLE UTILITIES
# =============================================================================

# OpenBoardView (portable program)
function bord
    set bord_path "./mnt/m.2_ssd/Programs (Portable)/Linux/OpenBoardView/bin/openboardview"
    if test -f "$bord_path"
        "$bord_path"
    else
        echo "OpenBoardView not found at $bord_path"
    end
end

# =============================================================================
# OTHER 
# =============================================================================

alias vpnon='protonvpn-cli c -f'
alias vpnoff='protonvpn-cli d'

# =============================================================================
# CLEANUP AND FINAL SETUP
# =============================================================================

function Sysclean
    echo "==> Checking failed systemd services..."
    systemctl --failed

    echo "==> Checking journal logs (priority 3)..."
    #    sudo journalctl -p 3 -xb

    echo "==> Updating system with pacman..."
    #    sudo pacman -Syu

    echo "==> Updating AUR packages with paru..."
    #    shelly

    echo "==> Cleaning pacman cache..."
    sudo pacman -Scc

    echo "==> Cleaning paru cache..."
    shelly -Scc

    echo "==> Removing unwanted dependencies..."
    shelly -Yc

    echo "==> Checking orphan packages..."
    pacman -Qtdq

    #    echo "==> Removing orphan packages..."
    #    set orphans (pacman -Qtdq)
    #    if test -n "$orphans"
    #    sudo pacman -Rns $orphans
    # else
    #    echo "No orphan packages to remove."
    # end

    echo "==> Cleaning user cache..."
    rm -rf ~/.cache/*

    echo "==> Vacuuming journal to 2 weeks..."
    sudo journalctl --vacuum-time=2weeks
end
# =============================================

# Set refresh rate script
function refresh
    if test -f "$HOME/.scripts/set_refresh_rate.sh"
        "$HOME/.scripts/set_refresh_rate.sh"
    else
        echo "Refresh rate script not found"
    end
end

# =============================================================================
# COMMENTED CONFIGURATIONS (PRESERVED FOR REFERENCE)
# =============================================================================

# Alternative package manager (uncomment to use paru instead of yay)
#alias yay='paru'

# RGB keyboard environment activation (bash-specific, needs Fish adaptation)
#alias rgbb='bash source rgbkb-env/bin/activate'

# Alternative prompt function (simpler version)
#function fish_prompt
#  printf '%s@%s:%s> ' (whoami) (hostname) (prompt_pwd)
#end

# Disable fastfetch greeting (uncomment to customize or disable)
function fish_greeting
    #    # Custom greeting or leave empty to disable fastfetch
end

# Alternative audio profile (headphones only, without speaker switching)
#alias Head='pactl set-card-profile alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic HiFi\ \(HDMI1\,\ HDMI2\,\ HDMI3\,\ Headphones\,\ Mic1\,\ Mic2\)'

# Speaker-only audio profile (without default sink setting)
#alias Speak='pactl set-card-profile alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"'

# Alternative neofetch command (simple version)
#alias neo='fastfetch'

# Distrobox containers (uncomment if using distrobox)
#alias ubu='distrobox-enter Ubuntu'     # Opens Ubuntu container
#alias fed='distrobox-enter fedora'     # Opens Fedora container

# Fedora-specific package management (uncomment for Fedora systems)
#alias uninstall='sudo dnf remove'

# GPU switching commands (for systems with switchable graphics)
#alias gpu='supergfxctl -g'             # See current GPU mode
#alias gpuhy='supergfxctl -m Hybrid'    # Switch to Hybrid mode
#alias gpuintel='supergfxctl -m Integrated'  # Switch to Intel GPU

# Alternative Grub configuration (for rpm-ostree systems)
#alias Grub='sudo rpm-ostree kargs --editor'

# Cache cleaning (be careful with this one)
#alias clean='rm -rf ~/.cache/*'

# Bash-specific aliases (Fish equivalents provided above)
#alias edital='vim ~/.bashrc'           # Use 'edital' function instead
#alias applyal='source ~/.bashrc'       # Use 'applyal' function instead

# Traditional ls command (replaced with eza above)
#alias ll='ls -alh'

# Alternative Limine configuration path
#alias Limine='sudo vim /efi/limine/limine.cfg'

# SDKMAN initialization (needs Fish adaptation)
# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# export SDKMAN_DIR="$HOME/.sdkman"
# [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
# export PATH="$HOME/.sdkman/candidates/java/current/bin:$PATH"

# Battery health management (alternative implementations)
#alias health-on='cd ~/.scripts/Acer/acer-wmi-battery/; sudo insmod acer-wmi-battery.ko enable_health_mode=1'
#alias health-off='cd ~/.scripts/Acer/acer-wmi-battery/; sudo insmod acer-wmi-battery.ko enable_health_mode=0'

# Alternative battery health commands (with manual module loading)
#alias health-on='cd ~/.scripts/Acer/acer-wmi-battery/; sudo insmod acer-wmi-battery.ko; echo 1 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode'
#alias health-off='cd ~/.scripts/Acer/acer-wmi-battery/; sudo insmod acer-wmi-battery.ko; echo 0 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode'

# Alternative Predator Sense implementations
#alias sense='sudo insmod ~/.scripts/Acer/PredatorSense/Linuwu-Sense/src/linuwu_sense.ko'
#alias sense='sudo modprobe platform_profile sudo modprobe sparse_keymap; sudo insmod ~/.scripts/Acer/PredatorSense/Linuwu-Sense/src/linuwu_sense.ko'

# Alternative Predator Blue application launcher
#alias pred='sudo ~/.scripts/Acer/PredatorSense/predator-blue/build/appPredatorBlue'

# Battery health monitoring script
#alias battery-health="~/.scripts/battery-health.sh"

# Alternative ls with exa (different options)
#alias ls='exa --grid --group-directories-first --only-dirs'

# Packet Tracer (uncomment if installed)
#alias packettracer='~/bin/packettracer-light'

# DNF update/upgrade restriction (Bash-specific, needs Fish adaptation)
#alias dnf='case "$1" in update|upgrade) echo "dnf update/upgrade is disabled";; *) /usr/bin/dnf "$@";; esac'

# Alternative fan curve aliases (replaced with functions above)
#alias fan-curve-gaming="sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --profile gaming; sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --daemon"
#alias fan-curve-balance="sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --profile balanced; sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --daemon"
#alias fan-curve-quite="sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --profile quiet; sudo python3 ~/.scripts/Acer/PredatorSense/Fan\ Curve/Fan_Curve.py --daemon"

# Alternative fan curve with systemd service
# systemctl --user start fan-curve.service

# Bash initialization (Bash-specific, not needed in Fish)
#bash -i -c 'source ~/.bashrc'

# =============================================================================
# END OF CONFIGURATION
# =============================================================================


# Added by Antigravity CLI installer
set -gx PATH "/home/sloppy/.local/bin" $PATH
