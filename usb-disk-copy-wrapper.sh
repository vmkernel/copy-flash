#!/bin/bash

# DESCRIPTION
# This scripts starts nested script and redirects its output to a log file

# INFO
# * udev runs scripts in root (/) folder
# * Using current date time as a part of a log file name is not a good idea, 
#   'cause RPi might not be able to connect to a NTP server to update current date/time,
#   but it still helps to determine which of the files newer

#### Settings ####
# Nested script path
SCRIPT_PATH='./usb-disk-copy.sh' 

# Path to a parent folder of a log files
LOG_FILE_FOLDER='/var/log/usb-disk-copy'

# Log file base name
LOG_FILE_BASE_NAME='debug'

# Path to a kill-switch file
# If the file exists, script will exit without executing the nested script
# Useful for debugging, to temporary disable auto-triggering by the udev rule
KILLSWITCH_PATH='/tmp/KILLSWITCH_USB_DISK_COPY'
#### End of settings ####

#------------------------------------------------------------------------------
SCRIPT_NAME=`basename "$0"`
echo ""
echo "THE SCRIPT HAS STARTED ($SCRIPT_NAME)"

#### Checking kill-switch
echo ""
echo "CHECKING THE KILLSWITCH..."

KILLSWITCH=$(ls -la "$KILLSWITCH_PATH" 2>/dev/null)
if [ -z "$KILLSWITCH" ]
then
    echo "The kill-switch is disabled."
else
    echo "*** WARNING *** The kill-switch is enabled. Exiting."
    exit 1
fi
#### End of checking kill-switch

#### Checking settings ####
echo ""
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

SCRIPT_EXIT_CODE=${PIPESTATUS[0]}
echo "THE NESTED SCRIPT HAS EXITED WITH CODE: $SCRIPT_EXIT_CODE"
if [ $SCRIPT_EXIT_CODE -ne 255 ]
then
    echo "THE DEVICE WILL BE HALTED SHORTLY!"
    #halt
else
    echo "THE DEVICE WILL STAY ON!"
fi

echo ""
echo "THE SCRIPT '$SCRIPT_NAME' HAS RUN TO ITS END."
#### End of starting nested script ####

exit 0
