#!/bin/bash

# INFO
# udev runs scripts in root (/) folder

# TODO: detect devices automatically: the first attached device sdX should be the destination device, the second sd(X+1) should be the source device.
# TODO: find a way to notify user when copy process has started and has finished.

#### SETTINGS ####
DST_DEVICE_NAME='sda1' # Source device name
SRC_DEVICE_NAME='sdb1' # Destination device name

SRC_DEVICE_MOUNT_POINT='/mnt/flash-dance/source'        # Source device's mount point
DST_DEVICE_MOUNT_POINT='/mnt/flash-dance/destination'   # Destination device's mount point

DST_FOLDER_ROOT='Incoming' # Destination folder's relative path (from destination device's root)
#### End of settings section


#### Main part ####
SCRIPT_NAME=`basename "$0"`
echo ""
echo "The script has started ($SCRIPT_NAME)"
echo "Reading settings..."
echo "Source device name is '$SRC_DEVICE_NAME'"
echo "Source device's mount point is '$SRC_DEVICE_MOUNT_POINT'"
echo "Destination device name is '$DST_DEVICE_NAME'"
echo "Destination device's mount moint is '$DST_DEVICE_MOUNT_POINT'"
echo "Destination folder's relative path is '$DST_FOLDER_ROOT'"


#### Checking settings ####
if [ -z "$DST_DEVICE_NAME" ]
then
    echo "ERROR: Destination device name is not set. Check settings! The script has terminated unexpectedly"
    exit 1
fi

if [ -z "$SRC_DEVICE_NAME" ]
then
    echo "ERROR: Source device name is not set. Check settings! The script has terminated unexpectedly"
    exit 1
fi

if [ -z "$DST_DEVICE_MOUNT_POINT" ]
then
    echo "ERROR: Destination mount point is not set. Check settings! The script has terminated unexpectedly"
    exit 1
else
    mkdir --parents $DST_DEVICE_MOUNT_POINT
fi

if [ -z "$SRC_DEVICE_MOUNT_POINT" ]
then
    echo "ERROR: Source mount point is not set. Check settings! The script has terminated unexpectedly"
    exit 1
else
    mkdir --parents $SRC_DEVICE_MOUNT_POINT
fi

if [ -z "$DST_FOLDER_ROOT" ]
then
    echo "ERROR: Destination folder is not set. Assuming root folder"
fi


#### Devices discovery ####
echo "Seaching for the devices..."

# Searching for a source device
SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
if [ -z "$SRC_DEVICE_ID" ]
then
    echo "ERROR: Source device not found. The script has terminated unexpectedly"
    exit 1
else
    echo "Source device found with name '$SRC_DEVICE_NAME' and id '$SRC_DEVICE_ID'"
fi

# Searching for a destination device
DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DST_DEVICE_NAME | awk '{print $9}')
if [ -z "$DST_DEVICE_ID" ]
then
    echo "ERROR: Destination device not found. The script has terminated unexpectedly"
    exit 1
else
    echo "Destination device found with name '$DST_DEVICE_NAME' and id '$DST_DEVICE_ID'"
fi


#### Checking if the mount points are free ####
echo "Checking mount points..."

# Unmounting the source mount point if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' is free"
else
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' is already in use, unmounting..."
    umount $SRC_DEVICE_MOUNT_POINT
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been successfully unmounted"
    else
        echo "ERROR: Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'. The script has terminated unexpectedly"
        exit 1
    fi
fi

# Unmounting the source mount point if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is free"
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is already in use, unmounting..."
    umount $DST_DEVICE_MOUNT_POINT
    MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been successfully unmounted"
    else
        echo "ERROR: Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'. The script has terminated unexpectedly"
        exit 1
    fi
fi


#### Mounting devices ####
# Mounting the devices to the mount points
echo "Mounting devices..."
echo "Mounting source device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT'..."
mount /dev/$SRC_DEVICE_NAME $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "ERROR: Unable to mount device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT. The script has terminated unexpectedly"
    exit 1
else
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' successfully mounted"
fi

echo "Mounting destination device '$DST_DEVICE_NAME' to mount point '$DST_DEVICE_MOUNT_POINT'..."
mount /dev/$DST_DEVICE_NAME $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "ERROR: Unable to mount device '$DST_DEVICE_NAME ' to mount point '$DST_DEVICE_MOUNT_POINT. The script has terminated unexpectedly"
    exit 1
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' successfully mounted"
fi


#### Generating destination folder path ####
echo "Generating destination root path..."
if [ -z "$DST_FOLDER_ROOT" ]
then
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT"
else
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT/$DST_FOLDER_ROOT"
fi

if [ -z "$DST_FOLDER_FULL_PATH" ]
then
    echo "ERROR: Unable to generate destination folder root path. The script has terminated unexpectedly"
    exit 1
else
    echo "Using destination folder root '$DST_FOLDER_FULL_PATH'"
fi

# TODO: fix potential bug. Every time Raspberry Pi stops it saves last known date and time and after the device starts
# it restores last known date and time. So the date and time in the device's operations system is incorrect until ntpd updates
# it from a NTP server. So I need to figure out another name for target folder based on different unique identifier.
# TODO: use original file creation date

#echo "Extracting current date and time..."
#DATE=$(date +"%F_%H-%M-%S")
#if [ -z "$DATE" ]
#then
#    echo "WARNING: Unable to generate nested folder with current date and time. Will use root folder as the destination"
#else
#    DST_FOLDER_FULL_PATH="$DST_FOLDER_FULL_PATH/$DATE"
#    if [ -z "$DST_FOLDER_FULL_PATH" ]
#    then
#        echo "ERROR: Unable to generate destination folder path. The script has terminated unexpectedly"
#        exit 1
#    else
#        echo "Using destination folder full path '$DST_FOLDER_FULL_PATH'"
#    fi
#fi

mkdir --parents $DST_FOLDER_FULL_PATH


#### Copying files ####
# TODO: use partial file for ability to resume copy after an interruption.
# TODO: use some kind of hash algorithms and auto rename to avoid collisions and rewrites.
echo "Starting file copy process from '$SRC_DEVICE_MOUNT_POINT' to '$DST_FOLDER_FULL_PATH'..."
#rsync --recursive --human-readable --progress $SRC_DEVICE_MOUNT_POINT $DST_FOLDER_FULL_PATH
EXIT_CODE=$?
echo "Copy process has finished with exit code is $EXIT_CODE"


#### Cleaning up ####
# Unmounting the destination devices from the mount point
umount -f $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been sucessfully unmounted"
else
    echo "ERROR: Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'. The device will halt in order to keep file system on the destination consistent"
#    halt
fi

#### Cleaning up ####
# Unmounting the source devices from the mount point
umount $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been sucessfully unmounted"
else
    echo "ERROR: Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'. The device will halt in order to keep file system on the source consistent"
#    halt
fi

echo "The script has run to it's end ($SCRIPT_NAME)"
echo ""
# halt
exit $EXIT_CODE