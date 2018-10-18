# List all attached SCSI disks /dev/sdX
SCSI_DISKS=($(ls -la /dev/sd* | grep -Pi "sd(\w+)(\d+)" | awk '{print $10}' | cut -f3 -d"/"))

# Display the SCSI disks array size
echo ${#SCSI_DISKS[@]}

# Walking through the array
for DISK_NAME in "${SCSI_DISKS[@]}"
do
   echo "Processing a SCSI disk with name $DISK_NAME..."
done

# Format folder name from current date & time
DATE=$(date +"%Y-%m-%d %H:%M") && echo $DATE