#!/bin/bash

#### SETTINGS ####
# Devices id patterns
SOURCE_DEVICE_ID_PATTERN='usb-.*part1'
DESTINATION_DEVICE_ID_PATTERN='ata-.*part1'

# Mount points
SOURCE_DEVICE_MOUNT_POINT='/mnt/sdcard'
DESTINATION_DEVICE_MOUNT_POINT='/mnt/hdd'


echo "The script has started"
echo ""
echo "Reading settings..."
echo "Source device ID pattern is '$SOURCE_DEVICE_ID_PATTERN'"
echo "Source device mount point is '$SOURCE_DEVICE_MOUNT_POINT'"
echo "Destination device ID pattern is '$DESTINATION_DEVICE_ID_PATTERN'"
echo "Destination device mount moint is '$DESTINATION_DEVICE_MOUNT_POINT'"

#### Devices discovery ####
echo ""
echo "Seaching for the devices..."
# Discovering source device name by id pattern
SOURCE_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SOURCE_DEVICE_ID_PATTERN | awk '{print $9}')
SOURCE_DEVICE_PATH=$(ls -la /dev/disk/by-id/ | grep -i $SOURCE_DEVICE_ID_PATTERN | awk '{print $11}')
SOURCE_DEVICE_NAME=$(ls -la /dev/disk/by-id/ | grep -i $SOURCE_DEVICE_ID_PATTERN | awk '{print $11}' | cut -f3 -d"/")

# Discovering destination device name by id pattern
DESTINATION_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DESTINATION_DEVICE_ID_PATTERN | awk '{print $9}')
DESTINATION_DEVICE_PATH=$(ls -la /dev/disk/by-id/ | grep -i $DESTINATION_DEVICE_ID_PATTERN | awk '{print $11}')
DESTINATION_DEVICE_NAME=$(ls -la /dev/disk/by-id/ | grep -i $DESTINATION_DEVICE_ID_PATTERN | awk '{print $11}' | cut -f3 -d"/")


## Cleaning up mount points ####
# Checking if a source device is found
if [ -z "$SOURCE_DEVICE_NAME" ]
then
    echo "Source device not found, exiting"
    exit -1
else
    echo "Source device found with name '$SOURCE_DEVICE_NAME' and id '$SOURCE_DEVICE_ID'"
fi

# Checking if a destination device is found
if [ -z "$DESTINATION_DEVICE_NAME" ]
then
    echo "Destination device not found, exiting"
    exit -1
else
    echo "Destination device found with name '$DESTINATION_DEVICE_NAME' and is '$DESTINATION_DEVICE_ID'"
fi


#### Checking if the mount points are free ####
echo ""
echo "Unmounting the mount points if they're already in use..."
# Unmounting the source mount point if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SOURCE_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SOURCE_DEVICE_MOUNT_POINT' is free"
else
    echo "The mount point '$SOURCE_DEVICE_MOUNT_POINT' is already in use, unmounting"
    # TODO: check if unmounted successfully, exit if not
    umount $SOURCE_DEVICE_MOUNT_POINT
fi

# Unmounting the source mount point if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DESTINATION_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DESTINATION_DEVICE_MOUNT_POINT' is free"
else
    echo "The mount point '$DESTINATION_DEVICE_MOUNT_POINT' is already in use, unmounting"
    # TODO: check if unmounted successfully, exit if not
    umount $DESTINATION_DEVICE_MOUNT_POINT
fi


#### Mounting devices ####
echo ""
echo "Mounting the devices..."
# Mounting the devices to the mount points
mount /dev/$SOURCE_DEVICE_NAME $SOURCE_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $SOURCE_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "Unable to mount device '$SOURCE_DEVICE_NAME' to mount point '$SOURCE_DEVICE_MOUNT_POINT, exiting"
    exit -2
else
    echo "The mount point '$SOURCE_DEVICE_MOUNT_POINT' successfully mounted"
fi

mount /dev/$DESTINATION_DEVICE_NAME $DESTINATION_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DESTINATION_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "Unable to mount device '$DESTINATION_DEVICE_NAME ' to mount point '$DESTINATION_DEVICE_MOUNT_POINT, exiting"
    exit -2
else
    echo "The mount point '$DESTINATION_DEVICE_MOUNT_POINT' successfully mounted"
fi


# Unmounting the devices from the mount point
#umount -f $SOURCE_DEVICE_MOUNT_POINT
#umount -f $DESTINATION_DEVICE_MOUNT_POINT

echo ""
echo "The script has run to it's end"
exit 0
