#!/bin/bash

# Discovering attached SCSI disks
echo "Discovering attached SCSI disks..."
ATTACHED_SCSI_DISKS=( $(ls -la /dev/ | grep -Pi "sd(\w+)1" | awk '{print $10}' | sort) )

if [ ${#ATTACHED_SCSI_DISKS[*]} -le 0 ]
then
    echo "*** WARNING *** No devices not found. The script has terminated prematurely."
    #exit 0
else
    echo "Found ${#ATTACHED_SCSI_DISKS[*]} device(s): ${ATTACHED_SCSI_DISKS[*]}"
fi

if [ ${#ATTACHED_SCSI_DISKS[*]} -lt 2 ]
then
    echo "*** WARNING *** Not enough devices to start copying. The script has terminated prematurely."
    #exit 0
else # Attached disks count greather than 2
    DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
    if [ -z "$DST_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Destination device name is not set. Check settings! The script has terminated unexpectedly."
        exit 1
    else
        echo "Found the destination device: /dev/$DST_DEVICE_NAME"
    fi

    SRC_DEVICE_NAME=${ATTACHED_SCSI_DISKS[1]}
    if [ -z "$SRC_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Source device name is not set. Check settings! The script has terminated unexpectedly."
        exit 1
    else
        echo "Found the source device: /dev/$SRC_DEVICE_NAME"  
    fi
fi
