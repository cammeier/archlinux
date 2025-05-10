#!/bin/bash
DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$DATE] Starting package update..." >> /home/cameron/update.log
# update_packages.sh
# Purpose: Update a predefined group of packages on Arch Linux using pacman.

# --- Configuration ---
# Define the list of packages you want to update here
PACKAGES_TO_UPDATE=(
    "curl"
    "nano"
    "git"
    "less"
)


# Check for root privileges (pacman requires root)
# if [ "$(id -u)" -ne 0 ]; then
#   echo "This script must be run as root or with sudo."
#   # No need to log here as it won't have permissions for /var/log yet.
#   exit 1
# fi
# --- Pacman Specific Operations ---
PACKAGE_MANAGER="pacman"

echo "Synchronizing package databases with pacman..."
# -Syy: Synchronize package databases. The double 'y' forces a refresh
# even if databases are considered up-to-date.
if ! pacman -Syy --noconfirm; then
    echo "Error: Failed to synchronize package databases with pacman. Check network or pacman configuration."
    exit 1
fi
echo "Package databases synchronized."

# --- Update Defined Packages ---
if [ ${#PACKAGES_TO_UPDATE[@]} -eq 0 ]; then
    echo "No packages specified for update. Please edit the script to add packages."
    exit 0
fi

echo "Attempting to update the following packages: ${PACKAGES_TO_UPDATE[*]}"

FAILED_PACKAGES=()
SUCCESS_PACKAGES=()
ALREADY_UP_TO_DATE_PACKAGES=()

for pkg in "${PACKAGES_TO_UPDATE[@]}"; do
    echo "-----------------------------------------------------"
    echo "Processing package: $pkg..."

    # Check if the package is installed and get its current version
    current_version_info=$(pacman -Qi "$pkg" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Package $pkg is not installed. Skipping."
        continue # Skip to the next package
    fi

    # Attempt to upgrade the package
    # -S: Synchronize (install/upgrade) packages.
    # --noconfirm: Suppress confirmation messages.
    # pacman -S <package> will upgrade it if it's installed and an update is available.
    # We capture output to check if it was already up-to-date.
    update_output=$(pacman -S --noconfirm "$pkg" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Check if pacman indicated the package was already up-to-date
        if echo "$update_output" | grep -q "is up to date"; then
            echo "Package $pkg is already up to date."
            ALREADY_UP_TO_DATE_PACKAGES+=("$pkg")
        else
            echo "Successfully updated $pkg."
            SUCCESS_PACKAGES+=("$pkg")
        fi
    else
        echo "Failed to update $pkg. See log for details."
        FAILED_PACKAGES+=("$pkg")
    fi
done

echo "-----------------------------------------------------"

# --- Summary ---
if [ ${#SUCCESS_PACKAGES[@]} -gt 0 ]; then
    echo "Successfully updated packages: ${SUCCESS_PACKAGES[*]}"
fi

if [ ${#ALREADY_UP_TO_DATE_PACKAGES[@]} -gt 0 ]; then
    echo "Packages already up to date: ${ALREADY_UP_TO_DATE_PACKAGES[*]}"
fi

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed to update packages: ${FAILED_PACKAGES[*]}"
    echo "Please check the log file for more details: $LOG_FILE"
    exit 1 # Exit with error if some packages failed
fi

if [ ${#SUCCESS_PACKAGES[@]} -eq 0 ] && [ ${#FAILED_PACKAGES[@]} -eq 0 ] && [ ${#ALREADY_UP_TO_DATE_PACKAGES[@]} -gt 0 ]; then
    echo "All specified packages were already up-to-date."
fi

if [ ${#SUCCESS_PACKAGES[@]} -eq 0 ] && [ ${#FAILED_PACKAGES[@]} -eq 0 ] && [ ${#ALREADY_UP_TO_DATE_PACKAGES[@]} -eq 0 ] && [ ${#PACKAGES_TO_UPDATE[@]} -gt 0 ]; then
    # This case implies packages were listed but not found (e.g., not installed)
    echo "No packages were updated. Check if they are installed or if there were other issues (see log)."
fi

DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$DATE] Package update finished." >> /home/cameron/update.log
exit 0
