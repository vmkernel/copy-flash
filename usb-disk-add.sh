#!/bin/bash

#### SETTINGS ####
# Devices id patterns
DST_DEVICE_NAME='sda1'
SRC_DEVICE_NAME='sdb1'

# Mount points
SRC_DEVICE_MOUNT_POINT='/mnt/flashdance/source'
DST_DEVICE_MOUNT_POINT='/mnt/flashdance/destination'

# Destination folder relative path (from destination device's root)
DST_FOLDER_ROOT='Incoming'
#### End of settings section


echo "The script has started"
echo ""
echo "Reading settings..."
echo "Source device name is '$SRC_DEVICE_NAME'"
echo "Source device's mount point is '$SRC_DEVICE_MOUNT_POINT'"
echo "Destination device name is '$DST_DEVICE_NAME'"
echo "Destination device's mount moint is '$DST_DEVICE_MOUNT_POINT'"
echo "Destination folder's relative path is '$DST_FOLDER_ROOT'"


#### Checking settings ####
if [ -z "$DST_DEVICE_NAME" ]
then
    echo "Destination device name is not set. Check settings! The script terminated unexpectedly."
    exit -1
fi

if [ -z "$SRC_DEVICE_NAME" ]
then
    echo "Source device name is not set. Check settings! The script terminated unexpectedly."
    exit -1
fi

if [ -z "$DST_DEVICE_MOUNT_POINT" ]
then
    echo "Destination mount point is not set. Check settings! The script terminated unexpectedly."
    exit -1
else
    mkdir --parents $DST_DEVICE_MOUNT_POINT
fi

if [ -z "$SRC_DEVICE_MOUNT_POINT" ]
then
    echo "Source mount point is not set. Check settings! The script terminated unexpectedly."
    exit -1
else
    mkdir --parents $SRC_DEVICE_MOUNT_POINT
fi

if [ -z "$DST_FOLDER_ROOT" ]
then
    echo "Destination folder is not set. Assuming root folder."
fi


#### Devices discovery ####
echo ""
echo "Seaching for the devices..."

# Searching for a source device
SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
if [ -z "$SRC_DEVICE_ID" ]
then
    echo "Source device not found. The script terminated unexpectedly."
    exit -1
else
    echo "Source device found with name '$SRC_DEVICE_NAME' and id '$SRC_DEVICE_ID'"
fi

# Searching for a destination device
DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DST_DEVICE_NAME | awk '{print $9}')
if [ -z "$DST_DEVICE_ID" ]
then
    echo "Destination device not found. The script terminated unexpectedly."
    exit -1
else
    echo "Destination device found with name '$DST_DEVICE_NAME' and id '$DST_DEVICE_ID'"
fi


#### Checking if the mount points are free ####
echo ""
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
        echo "Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'. The script terminated unexpectedly."
        exit -1
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
        echo "Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'. The script terminated unexpectedly."
        exit -1
    fi
fi


#### Mounting devices ####
echo ""
echo "Mounting devices..."
# Mounting the devices to the mount points
echo "Mounting source device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT'..."
mount /dev/$SRC_DEVICE_NAME $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "Unable to mount device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT, exiting"
    exit -2
else
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' successfully mounted"
fi

echo "Mounting destination device '$DST_DEVICE_NAME' to mount point '$DST_DEVICE_MOUNT_POINT'..."
mount /dev/$DST_DEVICE_NAME $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "Unable to mount device '$DST_DEVICE_NAME ' to mount point '$DST_DEVICE_MOUNT_POINT, exiting"
    exit -2
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' successfully mounted"
fi


#### Generating destination folder ####
echo ""
echo "Generating destination root path..."
if [ -z "$DST_FOLDER_ROOT" ]
then
    DST_FOLDER_FULL_PATH=$("$DST_DEVICE_MOUNT_POINT")
else
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT/$DST_FOLDER_ROOT"
fi

if [ -z "$DST_FOLDER_FULL_PATH" ]
then
    echo "Unable to generate destination folder root path. The script terminated unexpectedly."
    exit -1
else
    echo "Using destination folder root '$DST_FOLDER_FULL_PATH'"
fi

echo "Extracting current date and time..."
DST_FOLDER_NAME=$(date +"%Y-%m-%d %H-%M")
if [ -z "$DST_FOLDER_NAME" ]
then
    echo "Unable to generate nested folder with current date and time. Will use root folder as the destination."
else
    DST_FOLDER_FULL_PATH="$DST_FOLDER_FULL_PATH/$DST_FOLDER_NAME"
    if [ -z "$DST_FOLDER_FULL_PATH" ]
    then
        echo "Unable to generate destination folder path. The script terminated unexpectedly."
        exit -1
    else
        echo "Using destination folder full path '$DST_FOLDER_FULL_PATH'"
    fi
fi

mkdir --parents $DST_FOLDER_FULL_PATH


#### Copying files ####
echo "Starting file copy process from '$SRC_DEVICE_MOUNT_POINT' to '$DST_FOLDER_FULL_PATH'..."
#rsync --recursive --human-readable --progress $SRC_DEVICE_MOUNT_POINT $DST_FOLDER_FULL_PATH
echo "File copy process has finished"


#### Cleaning up ####
# Unmounting the source devices from the mount point
#umount $SRC_DEVICE_MOUNT_POINT
#MOUNT_STATUS=$(cat /proc/mounts | grep -i $SRC_DEVICE_MOUNT_POINT)
#if [ -z "$MOUNT_STATUS" ]
#then
#    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been sucessfully unmounted"
#else
#    echo "Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'."
#fi

# Unmounting the destination devices from the mount point
#umount -f $DST_DEVICE_MOUNT_POINT
#MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
#if [ -z "$MOUNT_STATUS" ]
#then
#    echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been sucessfully unmounted"
#else
#    echo "Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'."
#fi

echo ""
echo "The script has run to it's end"
exit 0
