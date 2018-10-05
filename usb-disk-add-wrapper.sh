#!/bin/bash

# DESCRIPTION
# This scripts starts nested script and redirects its output to a log file

# INFO
# udev runs scripts in root (/) folder

#### Settings ####
# TODO: learn the script to work with relative path
SCRIPT_PATH='/usr/local/etc/udev/scripts/usb-disk-add.sh' # Nested script's path
LOG_FILE_FOLDER='/var/log/flash-dance' # Path to a parent folder of a log files
LOG_FILE_BASE_NAME='debug' # Log file base name
#### End of settings ####


#### Main part ####
SCRIPT_NAME=`basename "$0"`
echo ""
echo "The script has started ($SCRIPT_NAME)"

#### Checking settings ####
echo "Checking settings..."
# Nested script's path
if [ -z "$SCRIPT_PATH" ]
then
    echo "ERROR: Nested script's path is not set"
    exit 1
else
    echo "Nested script's path is '$SCRIPT_PATH'"
fi

# Log files' root folder
if [ -z "$LOG_FILE_FOLDER" ]
then
    echo "WARNING: Log files' root folder is not set. Will use default path"
    $LOG_FILE_FOLDER='/var/log'
fi
echo "Log files' root folder path is '$LOG_FILE_FOLDER'"
mkdir --parents $LOG_FILE_FOLDER

# Log file's base name
if [ -z "LOG_FILE_BASE_NAME" ]
then
    echo "WARNING: Log files' base name is not set. Will use default name"
    $LOG_FILE_BASE_NAME='flash-dance'
fi


#### Generating log file name ####
echo "Generating log file name..."
DATE=$(date +"%F_%H-%M-%S")
if [ -z "$DATE" ]
then
    echo "WARNING: Unable to convert current date and time to string in order to use it in log file name. Will use failover log file name"
    LOG_FILE="$LOG_FILE_FOLDER/$LOG_FILE_BASE_NAME.log"
else
    LOG_FILE="$LOG_FILE_FOLDER/$LOG_FILE_BASE_NAME-$DATE.log"
fi
echo "Using log file '$LOG_FILE'."


echo "Starting nested script '$SCRIPT_PATH'..."
"$SCRIPT_PATH" | tee "$LOG_FILE"

echo "The script has run to it's end ($SCRIPT_NAME)"
echo ""

exit 0