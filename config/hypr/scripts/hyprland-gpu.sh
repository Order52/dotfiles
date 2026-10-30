#!/bin/bash
set -e

# --- Configuration ---
IGPU_RULE_FILE="/etc/udev/rules.d/90-igpu-dev-path.rules"
DGPU_RULE_FILE="/etc/udev/rules.d/91-dgpu-dev-path.rules"
HYPRLAND_CONFIG="$HOME/.config/hypr/config/environment.lua"
CONFIG_BACKUP="$HOME/.config/hypr/config/environment.lua.bak-$(date +%F-%T)"

# --- Colors ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'

# --- Helper Functions ---
print_info() {
    echo -e "${C_CYAN}[INFO]${C_RESET} $1"
}

print_success() {
    echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"
}

print_warning() {
    echo -e "${C_YELLOW}[WARN]${C_RESET} $1"
}

print_error() {
    echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2
}

check_config_file() {
    if [ ! -f "$HYPRLAND_CONFIG" ]; then
        print_error "Hyprland config not found at: $HYPRLAND_CONFIG"
        print_error "Please make sure Hyprland is installed and configured."
        exit 1
    fi
}

backup_config() {
    check_config_file
    print_info "Backing up $HYPRLAND_CONFIG to $CONFIG_BACKUP..."
    cp "$HYPRLAND_CONFIG" "$CONFIG_BACKUP"
    print_success "Backup created."
}

# --- Main Functions ---

apply_config() {
    print_info "Starting GPU configuration..."
    
    # We need sudo permission
    sudo -v
    if [ $? -ne 0 ]; then
        print_error "sudo permissions are required. Aborting."
        exit 1
    fi

    # 1. Find GPU IDs
    print_info "Detecting GPUs..."
    INTEL_ID=$(lspci -d ::03xx | grep 'Intel' | cut -f1 -d' ')
    NVIDIA_ID=$(lspci -d ::03xx | grep 'NVIDIA' | cut -f1 -d' ')

    if [ -z "$INTEL_ID" ]; then
        print_error "Could not find Intel GPU. Aborting."
        exit 1
    fi
    if [ -z "$NVIDIA_ID" ]; then
        print_error "Could not find NVIDIA GPU. Aborting."
        exit 1
    fi

    print_success "Found Intel GPU at: $INTEL_ID"
    print_success "Found NVIDIA GPU at: $NVIDIA_ID"

    # 2. Ask for primary GPU
    print_info "Which GPU do you want as the PRIMARY renderer for Hyprland?"
    print_warning "For laptops, 'Internal (Intel)' is highly recommended for battery life."
    
    local DEVICE_ORDER
    select choice in "Internal (Intel)" "Dedicated (NVIDIA)"; do
        case $REPLY in
            1)
                DEVICE_ORDER="/dev/dri/igpu:/dev/dri/dgpu"
                print_info "Setting Internal (Intel) as primary."
                break
                ;;
            2)
                DEVICE_ORDER="/dev/dri/dgpu:/dev/dri/igpu"
                print_info "Setting Dedicated (NVIDIA) as primary."
                break
                ;;
            *)
                print_error "Invalid option. Please enter 1 or 2."
                ;;
        esac
    done

    # 3. Create udev rules
    print_info "Creating udev rules..."

    # Intel (iGPU) rule
    # --- THIS IS THE FIX ---
    # KERNELS=="0000:$INTEL_ID" was changed to KERNELS=="$INTEL_ID"
    local UDEV_RULE_IGPU=$(cat <<EOF
KERNEL=="card*", \
KERNELS=="$INTEL_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/igpu"
EOF
)
    echo "$UDEV_RULE_IGPU" | sudo tee "$IGPU_RULE_FILE" > /dev/null

    # NVIDIA (dGPU) rule
    # --- THIS IS THE FIX ---
    # KERNELS=="0000:$NVIDIA_ID" was changed to KERNELS=="$NVIDIA_ID"
    local UDEV_RULE_DGPU=$(cat <<EOF
KERNEL=="card*", \
KERNELS=="$NVIDIA_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/dgpu"
EOF
)
    echo "$UDEV_RULE_DGPU" | sudo tee "$DGPU_RULE_FILE" > /dev/null
    
    print_success "Wrote udev rules to /etc/udev/rules.d/"

    # 4. Reload udev
    print_info "Reloading udev rules..."
    sudo udevadm control --reload
    sudo udevadm trigger
    
    print_warning "Waiting 3 seconds for udev to apply changes..."
    sleep 3

    # 5. Verify symlinks
    if [ ! -L /dev/dri/igpu ] || [ ! -L /dev/dri/dgpu ]; then
        print_error "Symlinks /dev/dri/igpu or /dev/dri/dgpu were NOT created."
        print_error "Something went wrong. Please check the udev rules in /etc/udev/rules.d/"
        print_warning "Running undo to clean up..."
        undo_config
        exit 1
    fi
    print_success "Symlinks created successfully:"
    ls -l /dev/dri/igpu /dev/dri/dgpu

    # 6. Configure Hyprland
    backup_config
    print_info "Updating $HYPRLAND_CONFIG..."

    # Remove any existing lines (from this script or manual attempts)
    sed -i '/^-- Added by hyprland-gpu-manager/d' "$HYPRLAND_CONFIG"
    sed -i '/^hl\.env("AQ_DRM_DEVICES"/d' "$HYPRLAND_CONFIG"

    # Add the new configuration
    {
        echo ""
        echo "-- Added by hyprland-gpu-manager"
        echo "hl.env(\"AQ_DRM_DEVICES\", \"$DEVICE_ORDER\")"
    } >> "$HYPRLAND_CONFIG"

    print_success "Hyprland configuration updated."
    print_info "\n------------------------------------------------------------"
    print_success "Configuration complete! Please REBOOT your system now."
    print_info "------------------------------------------------------------"
}

undo_config() {
    print_warning "Starting UNDO process..."
    
    # We need sudo permission
    sudo -v
    if [ $? -ne 0 ]; then
        print_error "sudo permissions are required. Aborting."
        exit 1
    fi

    # 1. Remove udev rules
    print_info "Removing udev rules..."
    sudo rm -f "$IGPU_RULE_FILE"
    sudo rm -f "$DGPU_RULE_FILE"
    print_success "Removed udev rule files."

    # 2. Reload udev
    print_info "Reloading udev rules..."
    sudo udevadm control --reload
    sudo udevadm trigger
    print_success "udev rules reloaded. Symlinks (/dev/dri/igpu, /dev/dri/dgpu) will be removed."

    # 3. Clean Hyprland config
    if [ -f "$HYPRLAND_CONFIG" ]; then
        # Only backup if we're not being called from a failed apply_config
        if [ -z "$1" ] || [ "$1" != "no-backup" ]; then
            backup_config
        fi
        print_info "Cleaning $HYPRLAND_CONFIG..."
        
        sed -i '/^-- Added by hyprland-gpu-manager/d' "$HYPRLAND_CONFIG"
        sed -i '/^hl\.env("AQ_DRM_DEVICES"/d' "$HYPRLAND_CONFIG"
        
        print_success "Removed AQ_DRM_DEVICES env from config."
    else
        print_warning "Hyprland config not found. Skipping cleanup."
    fi

    print_info "\n------------------------------------------------------------"
    print_success "UNDO complete! Please REBOOT to apply changes."
    print_info "------------------------------------------------------------"
}

# --- Main Menu ---
main() {
    clear
    echo -e "${C_GREEN}Hyprland Multi-GPU Manager${C_RESET}"
    echo "----------------------------"
    echo "This script will configure udev rules and your Hyprland"
    echo "config to select a primary GPU."
    echo ""
    echo "Your system:"
    lspci -d ::03xx | grep -E 'Intel|NVIDIA'
    echo "----------------------------"
    
    echo "What would you like to do?"
    select choice in "Apply/Change GPU Configuration" "Undo GPU Configuration" "Exit"; do
        case $REPLY in
            1)
                apply_config
                break
                ;;
            2)
                undo_config
                break
                ;;
            3)
                print_info "Exiting."
                break
                ;;
            *)
                print_error "Invalid option. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Run the script
main


