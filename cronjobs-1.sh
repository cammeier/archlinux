#!/bin/bash

export DISPLAY=:0
export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.G3H452

# Select date using Zenity calender picker and store into a variable
# check to make sure date was selected


selected_date=$(zenity --calendar --title="Select a Date" --text="Please choose a date:" --date-format="%Y-%m-%d")

# Check if a date was selected (exit code 0 means OK, non-empty output)
if [ $? -eq 0 ] && [ -n "$selected_date" ]; then
    echo "Selected date: $selected_date"
else
    echo "Error: No date was selected."
    exit 1
fi

# Select time (12-hour format) with zenity using --entry with HH:MM format and store into a variable
# check to make sure a valid format was entered

# Select time (12-hour format) with zenity using --entry with HH:MM format and store into a variable
selected_time=$(zenity --entry --title="Select a Time" --text="Enter time in HH:MM format (12-hour):")

# Check if a valid format was entered
if [[ $? -eq 0 ]] && [[ "$selected_time" =~ ^(0[1-9]|1[0-2]):[0-5][0-9]$ ]]; then
    echo "Selected time: $selected_time"
else
    echo "Error: Invalid time format or no time was entered."
    exit 1
fi


# Select AM or PM with zenity --list and check to make sure it was selected

# Select AM or PM with zenity --list and check to make sure it was selected
selected_period=$(zenity --list \
    --radiolist \
    --title="Select AM or PM" \
    --text="Choose AM or PM:" \
    --column "Select" \
    --column "Period" \
    TRUE AM \
    FALSE PM)

# Check if a valid selection was made
if [ $? -eq 0 ] && [ -n "$selected_period" ]; then
    echo "Selected period: $selected_period"
else
    echo "Error: No selection was made for AM or PM."
    exit 1
fi

# Convert 12-hour time to 24-hour time
# store the hour in a variable for hour
# store the minutes in a variable for minutes

hour=${selected_time:0:2}
minutes=${selected_time:3:2}
if [ "$selected_period" == "PM" ] && [ "$hour" != "12" ]; then
    hour=$((10#$hour + 12))
elif [ "$selected_period" == "AM" ] && [ "$hour" == "12" ]; then
    hour=0
elif [ "$selected_period" == "PM" ] && [ "$hour" == "12" ]; then
    hour=12
elif [ "$selected_period" == "AM" ]; then
    hour=$((10#$hour))
fi

# --- Add these lines to print the converted time ---
echo "Converted 24-hour hour: $hour"
echo "Minutes: $minutes"
# Select script file using zenity and store it in a variable
# check to make sure it was selected 

# Prompt user to select one file using Zenity file selection
selected_file=$(zenity --file-selection \
    --title "Select a File" \
    --filename "/home/${USER}/")

# Check if a file was selected (exit code 0 means OK, non-empty output)
if [ $? -eq 0 ] && [ -n "$selected_file" ]; then
    echo "Selected file: $selected_file"
else
    echo "Error: No file was selected."
    exit 1
fi

# Ask if the scheduled script needs DISPLAY and XAUTHORITY variables
# if you choose to use zenity to choose your files on the create_backup.sh you
# will need to use the display. Since the cronjob will run in the background
# you can use the DISPLAY and the XAURHORITY to display your gui
# use display="DISPLAY=:0" and xauthority="XAUTHORITY=/home/$USER/.Xauthority"
# to use your display

if grep -q "[[:space:]]zenity\>" "$selected_file"; then
    echo "Warning: The selected script contains 'zenity' and requires DISPLAY and XAUTHORITY."
    echo "Ensure the following are set in the script or cron environment:"
    echo "  export DISPLAY=:0"
    if [ -n "$XAUTHORITY" ]; then
        echo "  export XAUTHORITY=$XAUTHORITY"
    else
        echo "  (Note: No XAUTHORITY file found; may work in Wayland/XWayland if authentication is not required)"
    fi
    echo "A graphical session (Wayland with XWayland or X11) must be active, or the script will fail with 'Failed to open display'."
fi


# Select repetition schedule using Zenity --list and --column will be 
# Once a day, Once a week, Once a month, Once a year
repetition=$(zenity --list \
    --radiolist \
    --title="Select Repetition Schedule" \
    --text="How often should the script run?" \
    --column "Select" --column "Repetition" \
    TRUE "Once a day" \
    FALSE "Once a week" \
    FALSE "Once a month" \
    FALSE "Once a year")
if [ $? -eq 0 ] && [ -n "$repetition" ]; then
    echo "Selected repetition: $repetition"
else
    echo "Error: No repetition schedule was selected."
    exit 1
fi



# Calculate day and month for the initial run and store
# in a variable into day and variable for month

month=${selected_date:5:2}

day=${selected_date:8:2}

weekday=$(date -d "$selected_date" +%w)
# Use a case to define cron job schedule based on user's selection
# of the repetition selected from your Zenity list
# each selection would store in a variable the syntax for
# Every day at the selected time "$minute $hour * * *"
# Every week on the selected day of the week "$minute $hour * * $weekday"
# Every month on the selected day"$minute $hour $day * *"
# Every year on the selected date "$minute $hour $day $month *"

case "$repetition" in
    "Once a day")
        cron_schedule="$minutes $hour * * *"
        ;;
    "Once a week")
        cron_schedule="$minutes $hour * * $weekday"
        ;;
    "Once a month")
        cron_schedule="$minutes $hour $day * *"
        ;;
    "Once a year")
        cron_schedule="$minutes $hour $day $month *"
        ;;
    *)
        echo "Error: Invalid repetition schedule."
        exit 1
        ;;
esac



# Add the cron job using the variable that was created in the case and the display as well as the script

cron_file=$(mktemp)

# Include DISPLAY and XAUTHORITY in the cron job if the script uses Zenity
if grep -q "[[:space:]]zenity\>" "$selected_file"; then
    if [ -n "$XAUTHORITY" ]; then
        echo "$cron_schedule DISPLAY=:0 XAUTHORITY=$XAUTHORITY $selected_file" > "$cron_file"
    else
        echo "$cron_schedule DISPLAY=:0 $selected_file" > "$cron_file"
    fi
else
    echo "$cron_schedule $selected_file" > "$cron_file"
fi
crontab "$cron_file"
if [ $? -eq 0 ]; then
    echo "Cron job scheduled successfully."
else
    echo "Error: Failed to schedule cron job."
    rm "$cron_file"
    exit 1
fi
rm "$cron_file"

# Show confirmation
zenity --info --title="Cron Job Scheduled" --text="Script '$selected_file' scheduled to run $repetition at $selected_time $selected_period on $selected_date."
