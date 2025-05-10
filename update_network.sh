#!/bin/bash

# update_network.sh
# Purpose: Check network status and update common system network tools on Arch Linux (GNOME).

# --- Configuration ---
# Define the list of network-related packages you want to check and update.
# Add or remove packages as per your needs.
NETWORK_PACKAGES_TO_UPDATE=(
    "networkmanager"       # Core network management for GNOME
    "traceroute"           # Network diagnostic tool
    "nmap"                 # Network scanner (if you use it)
    "curl"                 # Data transfer utility
    "wget"                 # Network downloader
)



# Check for root privileges (pacman and some checks require root)
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  # Cannot log yet as we might not have permissions for LOG_FILE
  exit 1
fi

# --- Script Start ---
echo "Network Tools Updater for Arch Linux (GNOME)"

# --- Network Status Checks (Display Only) ---
echo "Performing initial network status checks..."

echo "[INFO] NetworkManager Service Status:"
systemctl status NetworkManager.service --no-pager | log_message # Pipe to log_message to capture multi-line output
echo ""

echo "[INFO] NetworkManager Device Status (nmcli):"
nmcli dev status | log_message
echo ""

echo "[INFO] IP Address Information (ip addr):"
ip addr show | log_message
echo ""

# --- Pacman Database Synchronization ---
echo "Synchronizing pacman package databases (pacman -Syy)..."
if ! pacman -Syy --noconfirm; then
    echo "FATAL ERROR: Failed to synchronize package databases with pacman. Check network or pacman configuration."
    exit 1
fi
echo "Package databases synchronized."

# --- Check and Update Defined Network Packages ---
if [ ${#NETWORK_PACKAGES_TO_UPDATE[@]} -eq 0 ]; then
    echo "No network packages specified for update. Please edit the script to add packages."
    exit 0
fi

echo "Checking and attempting to update the following network packages:"
echo "${NETWORK_PACKAGES_TO_UPDATE[*]}"

FAILED_UPDATES=()
SUCCESSFUL_UPDATES=()
ALREADY_UP_TO_DATE=()
NOT_INSTALLED_SKIPPED=()

for pkg in "${NETWORK_PACKAGES_TO_UPDATE[@]}"; do
    echo "Processing package: $pkg..."

    # Check if the package is installed
    if pacman -Q "$pkg" &>/dev/null; then
        current_version=$(pacman -Qi "$pkg" | grep "Version" | awk '{print $3}')
        echo "  [INFO] $pkg is installed (Version: $current_version)."

        echo "  Attempting to update $pkg..."
        # Attempt to upgrade the package. --noconfirm avoids interactive prompts.
        # Capture output to check if it was already up-to-date.
        update_output=$(sudo pacman -S --noconfirm "$pkg" 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ]; then
            if echo "$update_output" | grep -q "is up to date"; then
                echo "  [OK] $pkg is already up to date."
                ALREADY_UP_TO_DATE+=("$pkg")
            elif echo "$update_output" | grep -q "warning: $pkg-"; then # Covers reinstallation or minor changes
                 echo "  [OK] $pkg reinstalled/no effective update needed."
                 ALREADY_UP_TO_DATE+=("$pkg")
            else
                new_version=$(pacman -Qi "$pkg" | grep "Version" | awk '{print $3}')
                echo "  [SUCCESS] Successfully updated $pkg to $new_version."
                SUCCESSFUL_UPDATES+=("$pkg")
            fi
        else
            echo "  [FAIL] Failed to update $pkg. See log for details."
            FAILED_UPDATES+=("$pkg")
        fi
    else
        echo "  [INFO] $pkg is not installed. Skipping."
        NOT_INSTALLED_SKIPPED+=("$pkg")
    fi
    echo "" # Newline for readability
done

# --- Summary ---
echo "Network package update process finished."

if [ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]; then
    echo "Successfully updated packages: ${SUCCESSFUL_UPDATES[*]}"
fi
if [ ${#ALREADY_UP_TO_DATE[@]} -gt 0 ]; then
    echo "Packages already up to date: ${ALREADY_UP_TO_DATE[*]}"
fi
if [ ${#NOT_INSTALLED_SKIPPED[@]} -gt 0 ]; then
    echo "Packages not installed (skipped): ${NOT_INSTALLED_SKIPPED[*]}"
fi
if [ ${#FAILED_UPDATES[@]} -gt 0 ]; then
    echo "ERROR: Failed to update packages: ${FAILED_UPDATES[*]}"
    echo "Please check the log file for more details: $LOG_FILE"
    exit 1
fi

echo "All relevant checks and updates completed. See $LOG_FILE for details."
exit 0
