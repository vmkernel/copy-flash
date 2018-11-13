#!/bin/bash

### TODO ###
# * General: find a way to notify user when copy process has started and has finished (Issue #5).
# * rsync: auto rename different files with the same names to avoid skipping (Issue #8).
# * General: use original file creation date as a destination folder name in order to sort data by its real creation date (Issue #9).
# * General: if I'm using 'current' date and time in log file names why I shouldn't use the same name for destination folder, just to match a specific folder with a specific log file (Issue #9).
# * General: fix potential bug. Every time Raspberry Pi stops it saves last known date and time and after the device starts (Issue #9).
#            it restores last known date and time. So the date and time in the device's operations system is incorrect until ntpd updates
#            it from a NTP server. So I need to figure out another name for target folder based on different unique identifier.
# * General: add disk label information (Issue #13).
# * BUG: Fix multiple device ID output (Issue #14)
# * General: Check source and destiantion path and format it that way, so it doesn't have trailing slashes (Issue #15).

#### SETTINGS ####
# Source device mount point (without a trailing slash!)
# Specifies an EMPTY folder in a RPi file system to which a source volume will be mounted
# Examples: /media/usb0, /mnt/source
SRC_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/source'

# Destination device mount point (without a trailing slash)
# Specifies an EMPTY folder in a RPi file system to which a destination volume will be mounted
# Examples: /media/usb1, /mnt/destination
DST_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/destination'

# Destination folder relative path
# Specifies the path from destination volume's root folder to a destination folder
# If the parameter is not specified, files or separate folders (depending on IS_ALL_IN_ONE_FOLDER switch) will be placed in the root folder of a destination volume
DST_FOLDER_ROOT='Incoming'

# Separate folder name pattern and operations mode switch
# ALL-IN-ONE folder mode
#   USE WITH CAUTION!
#   If the parameter is NOT set, the script works in ALL-IN-ONE folder mode.
#   Places all files from all source volumes to a single destination directory.
#   No name collision resolution is implemented for now.
#
# SEPARATE folders mode
#   If the parameter IS set, specifies a pattern for a separate folder name that will be created for a source volume EVERY TIME the script starts.
#   Creates a separate folder for each source volume EVERY TIME the script starts.
#   Resuming is NOT supported.
#
#   Example: 
#       usbflash_XXXXXXXXXXXXXXXXXX
#       All the X-es will be replaced by mktmp command to random digits and letters.
DST_FOLDER_NAME_PATTERN=''
#### End of settings section


#------------------------------------------------------------------------------
SCRIPT_NAME=`basename "$0"`
echo ""
echo "THE SCRIPT HAS STARTED ($SCRIPT_NAME)"
echo "CHECKING SETTING..."
echo "Source device mount point: $SRC_DEVICE_MOUNT_POINT"
echo "Destination device mount moint: $DST_DEVICE_MOUNT_POINT"
echo "Destination folder relative path: $DST_FOLDER_ROOT"
echo "Destination folder name pattern: $DST_FOLDER_NAME_PATTERN"

#### Checking settings ####
if [ -z "$DST_DEVICE_MOUNT_POINT" ]
then
    echo "*** ERROR *** Destination mount point is not set. Check settings! The script has terminated unexpectedly."
    exit 1
else
    mkdir --parents $DST_DEVICE_MOUNT_POINT
fi

if [ -z "$SRC_DEVICE_MOUNT_POINT" ]
then
    echo "*** ERROR *** Source mount point is not set. Check settings! The script has terminated unexpectedly."
    exit 1
else
    mkdir --parents $SRC_DEVICE_MOUNT_POINT
fi

if [ -z "$DST_FOLDER_ROOT" ]
then
    echo "*** WARNING *** Destination folder is not set. Assuming root folder."
fi

IS_ALL_IN_ONE_FOLDER=1 # Operations mode switch, by default assuming all-in-one directory mode
if [ -z "$DST_FOLDER_NAME_PATTERN" ]
then
    echo "Operations mode: all-in-one folder (separate folder name pattern is NOT set)."
else
    IS_ALL_IN_ONE_FOLDER=0
    echo "Operations mode: separate folder (separate folder name pattern is set)."
fi
#### End of checking settings ####


#### Checking arguments
echo ""
echo "CHECKING ARGUMENTS..."
IS_BIND_TO_DEVICE=0 # no device binding by default
if [ -z "$1" ]
then
    echo "No device name is specified in the command line for the script. Will do a full scan."
else
    echo "Got the device name from the command line: $1"
    IS_DEVICE_PRESENT=$(ls -la /dev/ | grep -i $1)
    if [ -z "$IS_DEVICE_PRESENT" ]
    then
        echo "*** WARNING **** Unable to find the device from the command line '/dev/$1'. Will do a full scan."
    else
        echo "The specified device '/dev/$1' is attached to the system. Will try to bind to it."
        IS_BIND_TO_DEVICE=1
    fi
fi
#### End of checking arguments


#### Devices discovery ####
echo ""
echo "SEARCHING FOR DEVICES..."

# Enumerating all attached SCSI disks using name pattern /dev/sd*1
ATTACHED_SCSI_DISKS=( $(ls -la /dev/ | grep -Pi "sd(\w+)1" | awk '{print $10}' | sort) )

if [ ${#ATTACHED_SCSI_DISKS[*]} -le 0 ] # Checking for an empty array
then
    # Got an empty array, 'cuse no device was found
    echo "*** WARNING *** No devices found. The script has terminated prematurely."
    exit 0
else
    echo "Found ${#ATTACHED_SCSI_DISKS[*]} device(s): ${ATTACHED_SCSI_DISKS[*]}"
fi

# Checking if we have at least two disks
if [ ${#ATTACHED_SCSI_DISKS[*]} -lt 2 ] 
then
    # Exit if ther's less than two disks attached.
    echo "*** WARNING *** Not enough devices. Need at least two devices to start a copying process. The script has terminated prematurely."
    exit 0
else 
    # Attached two (2) or more disks
    DST_DEVICE_NAME=""
    SRC_DEVICE_NAME=""
    if [ $IS_BIND_TO_DEVICE -eq 1 ]
    then
        # Trying to bind to the specified device
        if [ "${ATTACHED_SCSI_DISKS[0]}" = "$1" ] # Comparing the attached device with the first device found in system
        then
            # If it's a match, then do nothing, assuming this is the destination device and it's just attached
            echo "*** WARNING *** Auto-detect is assuming the devices as the first device in the system and will use it as a destination device as soon as a source device appears. Waiting for a source device. The script has terminated prematurely."
            exit 0
        else
            # If it's NOT a match, assuming the first device as the destination device and the current device as a source.
            DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
            SRC_DEVICE_NAME=$1
            echo "Destination device name (auto-detect): $DST_DEVICE_NAME"
            echo "Source device name (auto-detect): $SRC_DEVICE_NAME"
        fi
    else # Performing sequential detection
        DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
        SRC_DEVICE_NAME=${ATTACHED_SCSI_DISKS[1]}
        echo "Destination device name (sequential detect): $DST_DEVICE_NAME"
        echo "Source device name (sequential detect): $SRC_DEVICE_NAME"
    fi

    # Checking if the destination device name is set correctly
    if [ -z "$DST_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Unable to get destination device name. The script has terminated unexpectedly."
        exit 1
    fi
    # Checking if the source device name is set correctly
    if [ -z "$SRC_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Unable to get source device name. The script has terminated unexpectedly."
        exit 1
    fi

    # Getting the destination device id
    DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DST_DEVICE_NAME | awk '{print $9}')
    if [ -z "$DST_DEVICE_ID" ]
    then
        echo "*** WARNING *** Unable to find destination device ID."
    else
        echo "Destination device id: $DST_DEVICE_ID"
    fi

    # Getting the source device id
    SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
    if [ -z "$SRC_DEVICE_ID" ]
    then
        echo "*** WARNING *** Unable to find source device ID."
    else
        echo "Source device id: $SRC_DEVICE_ID"
    fi
fi
#### End of devices discovery ####


#### Checking if the mount points are free ####
echo ""
echo "CHECKING MOUNT POINTS..."

## SOURCE
# Unmounting the source MOUNT POINT if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' is not mounted."
else
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' is already mounted, unmounting..."
    umount $SRC_DEVICE_MOUNT_POINT
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been successfully unmounted."
    else
        echo "*** ERROR *** Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'. The script has terminated unexpectedly."
        exit 1
    fi
fi

# Unmounting the source DEVICE if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_NAME)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The device '/dev/$SRC_DEVICE_NAME' is not mounted."
else
    echo "The device '/dev/$SRC_DEVICE_NAME' is already mounted, unmounting..."
    umount /dev/$SRC_DEVICE_NAME
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_NAME)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The device '/dev/$SRC_DEVICE_NAME' has been successfully unmounted."
    else
        echo "*** ERROR *** Unable to unmount device '/dev/$SRC_DEVICE_NAME'. The script has terminated unexpectedly."
        exit 1
    fi
fi

# DESTINATION
# Unmounting the source MOUNT POINT if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is not mounted."
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is already mounted, unmounting..."
    umount $DST_DEVICE_MOUNT_POINT
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been successfully unmounted."
    else
        echo "*** ERROR *** Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'. The script has terminated unexpectedly."
        exit 1
    fi
fi

# Unmounting the source DEVICE if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_NAME)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The device '/dev/$DST_DEVICE_NAME' is not mounted."
else
    echo "The device '/dev/$DST_DEVICE_NAME' is already mounted, unmounting..."
    umount /dev/$DST_DEVICE_NAME
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_NAME)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The device '/dev/$DST_DEVICE_NAME' has been successfully unmounted."
    else
        echo "*** ERROR *** Unable to unmount device '/dev/$DST_DEVICE_NAME'. The script has terminated unexpectedly."
        exit 1
    fi
fi
#### End of checking if the mount points are free ####


#### Mounting devices ####
# Mounting the devices to the mount points
echo ""
echo "MOUNTING DEVICES..."
echo "Mounting source device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT'..."
mount /dev/$SRC_DEVICE_NAME $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "*** ERROR *** Unable to mount device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT. The script has terminated unexpectedly."
    exit 1
else
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' successfully mounted."
fi

echo "Mounting destination device '$DST_DEVICE_NAME' to mount point '$DST_DEVICE_MOUNT_POINT'..."
mount /dev/$DST_DEVICE_NAME $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "*** ERROR *** Unable to mount device '$DST_DEVICE_NAME ' to mount point '$DST_DEVICE_MOUNT_POINT. The script has terminated unexpectedly."
    exit 1
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' successfully mounted."
fi
#### End of mounting devices ####


#### Generating destination folder path ####
echo ""
echo "PREPARING DESTINATION FOLDER..."
if [ -z "$DST_FOLDER_ROOT" ]
then
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT"
else
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT/$DST_FOLDER_ROOT"
fi

if [ -z "$DST_FOLDER_FULL_PATH" ]
then
    echo "*** ERROR *** Unable to generate destination folder root path. The script has terminated unexpectedly."
    exit 1
else
    echo "Using destination folder root '$DST_FOLDER_FULL_PATH'."
fi


# Checking of destination folder name pattern is specified
if [[ ! -z "$DST_FOLDER_NAME_PATTERN" ]]
then
    # Old-way, separate folder mode
    echo "Generating temporary folder..."
    DST_FOLDER_FULL_PATH_FAILOVER="$DST_FOLDER_FULL_PATH"
    DST_FOLDER_FULL_PATH="$(mktemp --directory $DST_FOLDER_FULL_PATH/$DST_FOLDER_NAME_PATTERN)"
    if [ -z "$DST_FOLDER_FULL_PATH" ]
    then
        echo "*** WARNING *** Unable to generate unique destination folder path. Will fail-over to all-in-one mode."
        IS_ALL_IN_ONE_FOLDER=1
        DST_FOLDER_FULL_PATH="$DST_FOLDER_FULL_PATH_FAILOVER"
        if [ -z "$DST_FOLDER_FULL_PATH" ]
        then
            echo "*** ERROR *** Unable to use failover path. The script has terminated unexpectedly."
            exit 1
        fi
    fi
fi
#### End of generating destination folder path ####


#### Copying files ####
echo ""
echo "STARTING FILE COPY PROCESS..."
echo "Source: $SRC_DEVICE_MOUNT_POINT (/dev/$SRC_DEVICE_NAME)"
echo "Destination: '$DST_FOLDER_FULL_PATH' (/dev/$DST_DEVICE_NAME)"

# TODO: Check source path and format it that way, so it does have trailing slash (Issue #15).
if [ $IS_ALL_IN_ONE_FOLDER -eq 1 ] # New-way, all-in-one folder mode
then
    rsync --recursive --human-readable --progress --times --append-verify "$SRC_DEVICE_MOUNT_POINT/" $DST_FOLDER_FULL_PATH
elif [ $IS_ALL_IN_ONE_FOLDER -eq 0 ] # Old-way, separate folder mode
then
    rsync --recursive --human-readable --progress --times "$SRC_DEVICE_MOUNT_POINT/" $DST_FOLDER_FULL_PATH
fi
EXIT_CODE=$?
echo "Copy process has finished. Exit code: $EXIT_CODE"
#### End of copying files ####


#### Cleaning up ####
echo ""
echo "UNMOUNTING DEVICES..."
# Unmounting the destination devices from the mount point
umount -f $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been sucessfully unmounted."
else
    echo "*** ERROR *** Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'."
fi


#### Cleaning up ####
# Unmounting the source devices from the mount point
umount $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been sucessfully unmounted."
else
    echo "*** ERROR *** Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'."
fi
#### End of cleaning up ####

echo ""
echo "THE SCRIPT HAS RUN TO ITS END ($SCRIPT_NAME)"

exit $EXIT_CODE
