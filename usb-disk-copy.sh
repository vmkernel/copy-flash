#!/bin/bash

### INFO ###
# udev runs scripts in root (/) folder

### TODO ###
# * General: detect devices automatically: the first attached device sdX should be the destination device, the second sd(X+1) should be the source device (Issue #4).
# * General: find a way to notify user when copy process has started and has finished (Issue #5).
# * rsync: store everything in one directory, use partial file to resume copy after an interruption (Issue #6).
# * rsync: use some kind of hash algorithms to avoid collisions and overwrites (Issue #7).
# * rsync: auto rename different files with the same names to avoid skipping (Issue #8).
# * General: use original file creation date as a destination folder name in order to sort data by its real creation date (Issue #9).
# * General: if I'm using 'current' date and time in log file names why I shouldn't use the same name for destination folder, just to match a specific folder with a specific log file (Issue #9).
# * General: fix potential bug. Every time Raspberry Pi stops it saves last known date and time and after the device starts (Issue #9).
# it restores last known date and time. So the date and time in the device's operations system is incorrect until ntpd updates
# it from a NTP server. So I need to figure out another name for target folder based on different unique identifier.


#### SETTINGS ####
DST_DEVICE_NAME='sda1' # Destination device name
SRC_DEVICE_NAME='sdb1' # Source device name

SRC_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/source'        # Source device's mount point
DST_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/destination'   # Destination device's mount point

DST_FOLDER_ROOT='Incoming' # Destination folder's relative path (from destination device's root)
DST_FOLDER_NAME_PATTERN='usbflash_XXXXXXXXXXXXXXXXXX' # Directory name pattern for mktemp command
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
    echo "*** ERROR *** Destination folder is not set. Assuming root folder."
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
            echo "Auto-detect has found the destination device: $DST_DEVICE_NAME"
            echo "Auto-detect has found the source device: $SRC_DEVICE_NAME"
        fi
    else # Performing sequential detection
        DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
        SRC_DEVICE_NAME=${ATTACHED_SCSI_DISKS[1]}
        echo "Sequential detect has found the destination device: $DST_DEVICE_NAME"
        echo "Sequential detect has found the source device: $SRC_DEVICE_NAME"
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
        echo "Destination device found with name '$DST_DEVICE_NAME'"
        echo "*** WARNING *** Unable to find destination device ID."
    else
        echo "Destination device found with name '$DST_DEVICE_NAME' and id '$DST_DEVICE_ID'"
    fi

    # Getting the source device id
    SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
    if [ -z "$SRC_DEVICE_ID" ]
    then
        echo "Source device found with name '$SRC_DEVICE_NAME'"
        echo "*** WARNING *** Unable to find source device ID."
    else
        echo "Source device found with name '$SRC_DEVICE_NAME' and id '$SRC_DEVICE_ID'"
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
if [ -z "$DST_FOLDER_NAME_PATTERN" ]
then
    echo "*** WARNING *** Destination folder name pattern is not set. Will use root folder as the destination path."
else
    echo "Generating temporary folder..."
    DST_FOLDER_FULL_PATH_FAILOVER="$DST_FOLDER_FULL_PATH"
    DST_FOLDER_FULL_PATH="$(mktemp --directory $DST_FOLDER_FULL_PATH/$DST_FOLDER_NAME_PATTERN)"
    if [ -z "$DST_FOLDER_FULL_PATH" ]
    then
        echo "*** WARNING *** Unable to generate unique destination folder path. Will use root folder as the destination path."
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
rsync --recursive --human-readable --progress $SRC_DEVICE_MOUNT_POINT $DST_FOLDER_FULL_PATH
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
