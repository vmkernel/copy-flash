# Unattended USB disk copy solution for Raspberry Pi
Raspbian scripts that copies data from one USB device to another. 

Designed to copy photos and videos from (micro)SD cards (which is used in photo and video cameras) to portable hard disk drive on-the-go. Fully automated and doesn't require any additional stuff like monitor, keyboard and so on... Just you, your SD card from a video/photo camera, portable hard disk drive and Raspberry Pi.

The script runs upon *udev* request when a new device/partition added to a system.
The first block device (and its first partition, *dev/sda1*) is considered as destination device.
The second block device (and its first partition, *dev/sdb1*) is considered as a source device.


## Limitations
- Can't inform a user about results of a copy operation and/or its state (running/failed/etc...)
- Assumes that the first plugged USB device is a **destination** device and it gets name **/dev/sda1**
- Assumes that the second (and the last) plugged USB device is a **source** device and it gets name **/dev/sdb1**


## Installation

### Create required folders
1. Create a folder for the sripts (e.g.: **/usr/local/etc/udev/scripts**)
```bash
sudo mkdir --parents /usr/local/etc/udev/scripts
```
2. Create a folder for log files (e.g.: **/var/log/usb-disk-copy**)
```bash
sudo mkdir --parents /var/log/usb-disk-copy
```

### Place the scripts into a working folder
1. Copy files **usb-disk-copy.sh** and **usb-disk-copy-wrapper.sh** to **/usr/local/etc/udev/scripts** or to another folder you prefer to use, just don't forget to use the appropriate path in udev rule file.
```bash
sudo cp ./usb-disk-copy.sh ./usb-disk-copy-wrapper.sh /usr/local/etc/udev/scripts/
```
2. Grant execute permission on both files.
```bash
sudo chmod u=rwx,go=r /usr/local/etc/udev/scripts/usb-disk-copy.sh /usr/local/etc/udev/scripts/usb-disk-copy-wrapper.sh
```

### Setup a service that will do the job
**udev** strictly limits amount of time for a script, that is specified in 'RUN' section.
In my case udev allows the script to run only 1 or 2 minutes and kills it afterwards. 
So it's necessary to offload all time-consuming logic to some kind of service. Fortunately, **systemd** has a simple solution for this.
1. Create a **systemd** service description file at **/etc/systemd/system/** (e.g.: **usb-disk-copy-@.service**)
```bash
sudo touch /etc/systemd/system/usb-disk-copy-@.service
```
2. Fill it with the following content:
```text
[Unit]
Description=USB disk copy service
BindTo=dev-%i.device

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'cd /usr/local/etc/udev/scripts/ && ./usb-disk-copy-wrapper.sh > /var/log/usb-disk-copy/wrapper.log'
```
**NOTE**: 
-**/usr/local/etc/udev/scripts/** must point to the same directory where you have copied the scripts.
-**/var/log/usb-disk-copy/** must point to an existing directory.
3. Reload systemd daemon
```bash
 sudo systemctl daemon-reload
```

### Setup an udev rule
1. Create log folder for wrapper script operations log
```bash
sudo mkdir --parents /var/log/udev/
```
2. Create (or edit the existing) an udev script file in **/etc/udev/rules.d/** with name **50-usb-disk.rules** and the following content:
```bash
ACTION=="add", KERNEL=="sd*", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", RUN+="/bin/systemctl --no-block start usb-disk-copy-@%k.service"
```
3. Restart udev daemon and check if there's no error messages in your terminal.
```bash
sudo service udev restart
```

### Plug'n'play
1. Plug a destination USB device **first** (to which all files will be copied).
2. Plug a source USB device (from which all the files will be copied) **after** you've plugged a destination device.
3. Wait until the activity LED(s) on your source (desitination) device(s) stop(s) blinking.
