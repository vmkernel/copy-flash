#!/bin/bash

ATTACHED_SCSI_DISKS=( $(ls -la /dev/sd?1 2> /dev/null | awk '{print $10}' | cut -f3 -d"/" | sort) )
if [ ${#ATTACHED_SCSI_DISKS[*]} -ge 2 ]
then
    # Everything is ok, using firs two devices as a destination (the first one) and a source (the second one)
    DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
    SRC_DEVICE_NAME=${ATTACHED_SCSI_DISKS[1]}
    echo "Found the destination device: /dev/$DST_DEVICE_NAME"
    echo "Found the source device: /dev/$SRC_DEVICE_NAME"
else
    echo "Devices aren't found"
    # Something went wrong. Exit here
fi
