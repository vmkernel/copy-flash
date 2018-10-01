#!/bin/bash

#### SETTINGS ####
# Devices id patterns
DST_DEVICE_NAME='sda1'
SRC_DEVICE_NAME='sdb1'

# Mount points
SRC_DEVICE_MOUNT_POINT='/mnt/flashdance/source'
DST_DEVICE_MOUNT_POINT='/mnt/flashdance/destination'
#### End of settings section


echo "The script has started"
echo ""
echo "Reading settings..."
echo "Source device name is '$SRC_DEVICE_NAME'"
echo "Source device mount point is '$SRC_DEVICE_MOUNT_POINT'"
echo "Destination device name is '$DST_DEVICE_NAME'"
echo "Destination device mount moint is '$DST_DEVICE_MOUNT_POINT'"

#### Devices discovery ####
echo ""
echo "Seaching for the devices..."

# Searching for a source device
SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $SRC_DEVICE_NAME | awk '{print $9}')
if [ -z "$SRC_DEVICE_ID" ]
then
    echo "Source device not found, exiting"
    exit -1
else
    echo "Source device found with name '$SRC_DEVICE_NAME' and id '$SRC_DEVICE_ID'"
fi

# Searching for a destination device
DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep -i $DST_DEVICE_NAME | awk '{print $9}')
if [ -z "$DST_DEVICE_ID" ]
then
    echo "Destination device not found, exiting"
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
    # TODO: check if unmounted successfully, exit if not
    umount $SRC_DEVICE_MOUNT_POINT
fi

# Unmounting the source mount point if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep -i $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is free"
else
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' is already in use, unmounting..."
    # TODO: check if unmounted successfully, exit if not
    umount $DST_DEVICE_MOUNT_POINT
fi


#### Mounting devices ####
echo ""
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


# Unmounting the devices from the mount point
#umount -f $SRC_DEVICE_MOUNT_POINT
#umount -f $DST_DEVICE_MOUNT_POINT

echo ""
echo "The script has run to it's end"
exit 0
