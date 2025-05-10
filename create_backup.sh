#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.G3H452
# Select a source directory or
# Use Zenity to select a source directory

if ! DISPLAY=:0 xset -q >/dev/null 2>&1; then
    echo "Error: No X display available (GTK warning: Failed to open display)."
    echo "Zenity requires an active graphical session (Wayland with XWayland or X11)."
    echo "$(date): No display available" >> /home/$USER/backup.log
    exit 1
fi

echo "$(date): create_backup.sh started" >> /home/$USER/backup.log

# Select the destination folder
source_dir=$(zenity --file-selection \
    --title="Select Source Directory" \
    --directory \
    --filename="/home/$USER/")
# If using Zeinty check if the user canceled the dialog


if [ $? -eq 0 ] && [ -n "$source_dir" ]; then
    echo "Selected source directory: $source_dir" >> /home/$USER/backup.log
else
    echo "Error: No source directory selected or dialog canceled." >> /home/$USER/backup.log
    zenity --error --title="Backup Error" --text="No source directory selected." --width=300
    exit 1
fi
# Use Zenity to select the destination folder
dest_dir=$(zenity --file-selection \
    --title="Select Destination Directory" \
    --directory \
    --filename="/home/$USER/")

# If using Zeinty check if the user canceled the dialog

if [ $? -eq 0 ] && [ -n "$dest_dir" ]; then
    echo "Selected source directory: $dest_dir" >> /home/$USER/backup.log
else
    echo "Error: No source directory selected or dialog canceled." >> /home/$USER/backup.log
    zenity --error --title="Backup Error" --text="No source directory selected." --width=300
    exit 1
fi




# Create a tarball of the source folder and backup
source_dir_basename=$(basename "$source_dir")
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_file="$dest_dir/${source_dir_basename}_backup_$timestamp.tar.gz"


# Create a tarball of the source folder and backup
# Using -P to preserve absolute paths if source_dir is absolute,
# though tar usually warns and strips leading '/' by default.
# Using C to change directory to the parent of source_dir, then tarring source_dir_basename
# This avoids including the full path in the archive.
# For example, if source_dir is /home/user/Documents, it will archive 'Documents' folder
# instead of 'home/user/Documents'
parent_dir=$(dirname "$source_dir")

# Check if source_dir is a valid directory
if [ ! -d "$source_dir" ]; then
    log_message "Error: Source directory '$source_dir' does not exist or is not a directory."
    zenity --error \
        --title="Backup Error" \
        --text="Source directory '$source_dir' is not valid. Backup aborted." \
        --width=400
    exit 1
fi

# Check if destination directory is writable
if [ ! -w "$dest_dir" ]; then
    log_message "Error: Destination directory '$dest_dir' is not writable."
    zenity --error \
        --title="Backup Error" \
        --text="Destination directory '$dest_dir' is not writable. Backup aborted." \
        --width=400
    exit 1
fi


# Perform the backup using tar
# -c: create archive
# -z: compress with gzip
# -p: preserve permissions
# -f: specify archive file
# -C: change to directory before adding files
# The last argument is the directory to archive (relative to the -C path)
if tar -czpf "$backup_file" -C "$parent_dir" "$source_dir_basename"; then
    # Display success message
    zenity --info \
        --title="Backup Complete" \
        --text="Backup created successfully:\n$backup_file" \
        --width=400
else
    # If tar command fails
    error_code=$?
    log_message "Error: Backup creation failed with error code $error_code. Tar output might be in system logs or terminal if run manually."
    # Attempt to remove partially created backup file, if any
    if [ -f "$backup_file" ]; then
        rm "$backup_file"
        log_message "Removed partially created backup file: $backup_file"
    fi
    zenity --error \
        --title="Backup Failed" \
        --text="An error occurred during backup creation.\nCheck log file for details:\n$LOG_FILE" \
        --width=400
    exit 1
fi



# If using Zenity display the success or failure of the backup


zenity --info \
    --title="Backup Complete" \
    --text="Backup created successfully: $backup_file" \
    --width=300