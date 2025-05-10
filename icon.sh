#!/bin/bash

export DISPLAY=:0

export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.G3H452


# Use Zenity to prompt user to select the script (.sh file) to run and store in a variable
selected_script=$(zenity --file-selection \
    --title="Select a Script File" \
    --filename="/home/$USER/" \
    --file-filter="Shell Scripts | *.sh")

# If no script is selected, exit
if [ $? -eq 0 ] && [ -n "$selected_script" ]; then
    echo "Selected script: $selected_script"
else
    echo "Error: No script was selected."
    exit 1
fi

# Use Zenity to prompt user to select an image to use as the icon and store in a variable
selected_icon=$(zenity --file-selection \
    --title="Select an Icon Image" \
    --filename="/home/$USER/" \
    --file-filter="Images | *.png *.jpg *.jpeg *.svg")

# If no image is selected, exit
if [ $? -eq 0 ] && [ -n "$selected_icon" ]; then
    echo "Selected icon: $selected_icon"
else
    echo "Error: No icon image was selected."
    exit 1
fi


# Use Zenity to prompt user to enter a name for the desktop entry and store in a variable
desktop_name=$(zenity --entry \
    --title="Desktop Entry Name" \
    --text="Enter a name for the desktop entry:")

# If no name is entered, use a default name
if [ -z "$desktop_name" ]; then
    desktop_name="Script Launcher"
    echo "No name entered; using default: $desktop_name"
else
    echo "Desktop entry name: $desktop_name"
fi

# Define the path for the .desktop file (in the current directory) and store in a variable
desktop_file="./${desktop_name// /_}.desktop"

# Create the .desktop file using echo commands
# You can echo the content with the variables that you created
# using all the variables that were stored for path
# and zenity. The first line will be redirected >
# the following lines will be added with >>
echo "[Desktop Entry]" > "$desktop_file"
echo "Version=1.0" >> "$desktop_file"
echo "Type=Application" >> "$desktop_file"
echo "Name=$desktop_name" >> "$desktop_file"
echo "Exec=$selected_script" >> "$desktop_file"
echo "Icon=$selected_icon" >> "$desktop_file"
echo "Terminal=false" >> "$desktop_file"
echo "Categories=Utility;" >> "$desktop_file"

# Copy the .desktop file to the user's desktop
desktop_path="/home/$USER/Desktop/"
cp "$desktop_file" "$desktop_path"
if [ $? -eq 0 ]; then
    echo "Copied $desktop_file to $desktop_path"
else
    echo "Error: Failed to copy .desktop file to Desktop."
    exit 1
fi

# Make the .desktop file executable
chmod +x "$desktop_path/${desktop_file##*/}"
if [ $? -eq 0 ]; then
    echo "Made ${desktop_file##*/} executable."
else
    echo "Error: Failed to make .desktop file executable."
    exit 1
fi

# Use Zenity to notify user that the .desktop file has been created and moved
zenity --info \
    --title="Desktop Entry Created" \
    --text="Desktop entry '$desktop_name' has been created and moved to your Desktop."