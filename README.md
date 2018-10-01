# copy-flash
Raspbian scripts that copies data from one USB device to another. 

Originally designed to copy photos and videos from SD cards (which is used in photo and video cameras) to portable hard disk drive on-the-go.
The script runs upon udev request fully automated and doesn't require any additional stuff like monitor, keyboard and so on...
Just you, SD card from a video/photo camera, portable hard disk drive and Raspberry Pi.

The first block device (and its first partition) connected to Raspberry Pi (/dev/sda1) is considered as destination device.
The second block device (and its first partition) connected to Raspberry Pi (dev/sdb1) is considered as a source device.
