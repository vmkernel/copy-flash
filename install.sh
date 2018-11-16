#!/bin/bash

CURRENT_DIRECTORY=$(pwd)
if [ -z $CURRENT_DIRECTORY ]
then
    echo "Unable to determine current directory. The script has terminated unexpectedly."
    exit 1
fi

# Linking udev rules file
echo "Linking udev rules file..."
rm /etc/udev/rules.d/50-usb-disk.rules
ln --symbolic "$CURRENT_DIRECTORY/50-usb-disk.rules" /etc/udev/rules.d/
service udev restart

echo "Linking systemd one-shot service..."
# Linking systemd one-shot service
rm /etc/systemd/system/usb-disk-copy-@.service
ln --symbolic "$CURRENT_DIRECTORY/usb-disk-copy-@.service" /etc/systemd/system/
systemctl daemon-reload

echo "The script has successfully completed."