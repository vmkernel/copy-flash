# Here's some magic to convers standard ls -R output from:
#     $ ls -R /home/pi
#     /home/pi:
#     scripts
#
#     /home/pi/scripts:
#     rpi-usb-disk-copy
#
#     /home/pi/scripts/rpi-usb-disk-copy:
#     50-usb-disk.rules  debug-disable.sh  debug-enable.sh  install.sh  LICENSE  README.md  usb-disk-copy-@.service  usb-disk-copy.sh  usb-disk-copy-wrapper.sh
#
# to something more convenient to work with:
#     /home/pi/scripts
#     /home/pi/scripts/rpi-usb-disk-copy
#     /home/pi/scripts/rpi-usb-disk-copy/50-usb-disk.rules
#     /home/pi/scripts/rpi-usb-disk-copy/debug-disable.sh
#     /home/pi/scripts/rpi-usb-disk-copy/debug-enable.sh
#     /home/pi/scripts/rpi-usb-disk-copy/install.sh
#     /home/pi/scripts/rpi-usb-disk-copy/LICENSE
#     /home/pi/scripts/rpi-usb-disk-copy/README.md
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy-@.service
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy.sh
#     /home/pi/scripts/rpi-usb-disk-copy/usb-disk-copy-wrapper.sh
ls --recursive /home/pi | awk '/:$/&&f{s=$0;f=0};/:$/&&!f{sub(/:$/,"");s=$0;f=1;next};NF&&f{ print s"/"$0}'