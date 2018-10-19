# Unattended USB disk copy solution for Raspberry Pi
Raspbian scripts that copies data from one USB device to another. 

Designed to copy photos and videos from (micro)SD cards (which is used in photo and video cameras) to portable hard disk drive on-the-go. Fully automated and doesn't require any additional stuff like monitor, keyboard and so on... Just you, your SD card from a video/photo camera, portable hard disk drive and Raspberry Pi.

The script runs upon *udev* request when a new device/partition added to a system.
The first block device (and its first partition, *dev/sda1*) is considered as destination device.
The second block device (and its first partition, *dev/sdb1*) is considered as a source device.


## Installation

### Place the scripts into a working folder
1. Create a folder for the sripts (for example, **/usr/local/etc/udev/scripts**)
```bash
sudo mkdir --parents /usr/local/etc/udev/scripts
```
2. Copy files **usb-disk-add.sh** and **usb-disk-add-wrapper.sh** to **/usr/local/etc/udev/scripts** or to another folder you prefer to use, just don't forget to use the appropriate path in udev rule file.
```bash
sudo cp ./usb-disk-add.sh ./usb-disk-add-wrapper.sh /usr/local/etc/udev/scripts/
```
3. Grant execute permission on both files.
```bash
sudo chmod u=rwx,go=r /usr/local/etc/udev/scripts/usb-disk-add.sh /usr/local/etc/udev/scripts/usb-disk-add-wrapper.sh
```

### Setup a rule for udev
1. Create log folder for wrapper script operations log
```bash
sudo mkdir --parents /var/log/udev/
```
2. Create (or edit the existing) an udev script file in **/etc/udev/rules.d/** with name **50-usb-disk.rules** and the following content:
```bash
ACTION=="add", KERNEL=="sd*", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", RUN+="/bin/bash -c '/usr/local/etc/udev/scripts/usb-disk-add-wrapper.sh > /var/log/udev/usb-disk-add-wrapper.log'"
```
3. Restart udev daemon and check if there's no error messages in your terminal.
```bash
sudo service udev restart
```