# sourcing a check_file_collision function
./draft_check-files-collision.sh

SRC_DEVICE_MOUNT_POINT="/home/pi/scripts/rpi-usb-disk-copy" # debug line
DST_FOLDER_FULL_PATH="/tmp" # debug line

SOURCE_FILES=( $(find $SRC_DEVICE_MOUNT_POINT -type f,l) )
echo "Found ${#SOURCE_FILES[*]} file(s)"
for SOURCE_FILE_PATH in "${SOURCE_FILES[@]}"
do
    echo "Processing file '$SOURCE_FILE_PATH'"
    check_files_collision "$SRC_DEVICE_MOUNT_POINT" "$DST_FOLDER_FULL_PATH" "$SOURCE_FILE_PATH"
    EXIT_CODE=$?
    echo "Exit code: $EXIT_CODE"
done