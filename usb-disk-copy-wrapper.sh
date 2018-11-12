#!/bin/bash

# DESCRIPTION
# This scripts starts nested script and redirects its output to a log file

# INFO
# * udev runs scripts in root (/) folder
# * Using current date time as a part of a log file name is not a good idea, 
#   'cause RPi might not be able to connect to a NTP server to update current date/time,
#   but it still helps to determine which of the files newer

#### Settings ####
SCRIPT_PATH='./usb-disk-copy.sh' # Nested script's path
LOG_FILE_FOLDER='/var/log/usb-disk-copy' # Path to a parent folder of a log files
LOG_FILE_BASE_NAME='debug' # Log file base name
#### End of settings ####

#------------------------------------------------------------------------------
SCRIPT_NAME=`basename "$0"`
echo ""
echo "THE SCRIPT HAS STARTED ($SCRIPT_NAME)"
echo ""

#### Checking kill-switch
if [[ ! -z "$KILLSWITCH_USB_DISK_COPY" ]]
then
    echo "*** WARNING *** The script has detected that the killswitch is active. Exiting."
    exit 1
fi
#### End of checking kill-switch

#### Checking settings ####
echo "CHECKING SETTINGS..."
# Nested script's path
if [ -z "$SCRIPT_PATH" ]
then
    echo "*** ERROR *** Nested script path is not set."
    exit 1
else
    echo "Nested script path: $SCRIPT_PATH"
fi

# Log files' root folder
if [ -z "$LOG_FILE_FOLDER" ]
then
    echo "*** WARNING *** Log files root folder is not set. Will use default path."
    $LOG_FILE_FOLDER='/var/log'
fi
echo "Log files root folder path: $LOG_FILE_FOLDER"
mkdir --parents $LOG_FILE_FOLDER

# Log file's base name
if [ -z "LOG_FILE_BASE_NAME" ]
then
    echo "*** WARNING *** Log files base name is not set. Will use default name."
    $LOG_FILE_BASE_NAME='flash-dance'
fi
#### End of checking settings ####


#### Checking arguments
echo ""
echo "CHECKING ARGUMENTS..."
if [ -z "$1" ]
then
    echo "No device name is specified in command line for the script."
else
    echo "Got the device name from command line: $1"
fi
#### End of checking arguments


#### Generating log file name ####
echo ""
echo "GENERATING LOG FILE NAME..."
DATE=$(date +"%F_%H-%M-%S")
if [ -z "$DATE" ]
then
    echo "*** WARNING *** Unable to convert current date and time to string in order to use it in log file name. Will use failover log file name."
    LOG_FILE="$LOG_FILE_FOLDER/$LOG_FILE_BASE_NAME.log"
else
    LOG_FILE="$LOG_FILE_FOLDER/$LOG_FILE_BASE_NAME-$DATE.log"
fi
echo "Using log file: $LOG_FILE"
#### End of generating log file name ####


#### Starting nested script ####
echo ""
echo "STARTING NESTED SCRIPT '$SCRIPT_PATH'..."
if [ -z "$1" ]
then
    "$SCRIPT_PATH" | tee "$LOG_FILE"
else
    "$SCRIPT_PATH" $1 | tee "$LOG_FILE"
fi

echo ""
echo "THE SCRIPT '$SCRIPT_NAME' HAS RUN TO ITS END."
#### End of starting nested script ####

exit 0
