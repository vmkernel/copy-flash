# Use find with -type f(file), l(symlink) to list all files in a specified directory.
# Example:
#     /home/pi/scripts/rpi-usb-disk-copy/50-usb-disk.rules
#     /home/pi/scripts/rpi-usb-disk-copy/debug-disable.sh
#     /home/pi/scripts/rpi-usb-disk-copy/debug-enable.sh
#     /home/pi/scripts/rpi-usb-disk-copy/install.sh
#     /home/pi/scripts/rpi-usb-disk-copy/LICENSE
#     /home/pi/scripts/rpi-usb-disk-copy/README.md
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy-@.service
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy.sh
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy-wrapper.sh

SRC_DEVICE_MOUNT_POINT="/home/pi/scripts/rpi-usb-disk-copy" # debug line
DST_FOLDER_FULL_PATH="/tmp"

SOURCE_FILES=( $(find $SRC_DEVICE_MOUNT_POINT -type f,l) )
echo "Found ${#SOURCE_FILES[*]} file(s)"
for SOURCE_FILE_PATH in "${SOURCE_FILES[@]}"
do
    echo "Processing file '$SOURCE_FILE_PATH'"
done