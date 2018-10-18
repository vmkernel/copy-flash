# Unattended USB disk copy solution for Raspberry Pi
Raspbian scripts that copies data from one USB device to another. 

Designed to copy photos and videos from (micro)SD cards (which is used in photo and video cameras) to portable hard disk drive on-the-go. Fully automated and doesn't require any additional stuff like monitor, keyboard and so on... Just you, your SD card from a video/photo camera, portable hard disk drive and Raspberry Pi.

The script runs upon *udev* request when a new device/partition added to a system.
The first block device (and its first partition, *dev/sda1*) is considered as destination device.
The second block device (and its first partition, *dev/sdb1*) is considered as a source device.


## Installation
