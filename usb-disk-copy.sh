#!/bin/bash

### INFO ###
# udev runs scripts in root (/) folder

### TODO ###
# * General: detect devices automatically: the first attached device sdX should be the destination device, the second sd(X+1) should be the source device.
# * General: find a way to notify user when copy process has started and has finished.
# * rsync: store everything in one directory, use partial file to resume copy after an interruption.
# * rsync: use some kind of hash algorithms and auto rename to avoid collisions and overwrites.
# * General: use original file creation date as a destination folder name in order to sort data by its real creation date
# * General: fix potential bug. Every time Raspberry Pi stops it saves last known date and time and after the device starts.
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


#### Main part ####
SCRIPT_NAME=`basename "$0"`
echo ""
echo "THE SCRIPT HAS STARTED ($SCRIPT_NAME)"
echo "CHECKING SETTING..."
echo "Source device name: $SRC_DEVICE_NAME"
echo "Source device mount point: $SRC_DEVICE_MOUNT_POINT"
echo "Destination device name: $DST_DEVICE_NAME"
echo "Destination device mount moint: $DST_DEVICE_MOUNT_POINT"
echo "Destination folder relative path: $DST_FOLDER_ROOT"
echo "Destination folder name pattern: $DST_FOLDER_NAME_PATTERN"

#### Checking settings ####
if [ -z "$DST_DEVICE_NAME" ]
then
    echo "*** ERROR *** Destination device name is not set. Check settings! The script has terminated unexpectedly."
    exit 1
fi

if [ -z "$SRC_DEVICE_NAME" ]
then
    echo "*** ERROR *** Source device name is not set. Check settings! The script has terminated unexpectedly."
    exit 1
fi

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


#### Devices discovery ####
echo ""
echo "SEARCHING FOR DEVICES..."

# Searching for a destination device
DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DST_DEVICE_NAME | awk '{print $9}')
if [ -z "$DST_DEVICE_ID" ]
then
    echo "*** WARNING *** Destination device not found, nowhere to copy to. The script has terminated prematurely."
    exit 0
else
    echo "Destination device found with name '$DST_DEVICE_NAME' and id '$DST_DEVICE_ID'"
fi

# Searching for a source device
SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
if [ -z "$SRC_DEVICE_ID" ]
then
    echo "*** WARNING *** Source device not found, nowhere to copy from. The script has terminated prematurely."
    exit 0
else
    echo "Source device found with name '$SRC_DEVICE_NAME' and id '$SRC_DEVICE_ID'"
fi


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


#### Copying files ####
echo ""
echo "STARTING FILE COPY PROCESS..."
echo "Source: $SRC_DEVICE_MOUNT_POINT (/dev/$SRC_DEVICE_NAME)"
echo "Destination: '$DST_FOLDER_FULL_PATH' (/dev/$DST_DEVICE_NAME)"
rsync --recursive --human-readable --progress $SRC_DEVICE_MOUNT_POINT $DST_FOLDER_FULL_PATH
EXIT_CODE=$?
echo "Copy process has finished. Exit code: $EXIT_CODE"


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

echo ""
echo "THE SCRIPT HAS RUN TO ITS END ($SCRIPT_NAME)"

exit $EXIT_CODE
