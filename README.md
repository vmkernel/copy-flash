# Unattended USB disk copy solution for Raspberry Pi
Raspbian scripts that copies data from one USB storage device to another. 

Originally designed to copy photos and videos on-the-go from (micro)SD cards (which is used in photo and video cameras) to portable hard disk drive. Fully automated and doesn't require any additional stuff like monitor, keyboard and so on... Just you, your SD card from a video/photo camera, portable hard disk drive and Raspberry Pi.

The script runs upon **udev** request when a new device/partition added to a system.
The first block device (and its first partition, **dev/sda1**) is considered as destination device.
The second block device (and its first partition, **dev/sdb1**) is considered as a source device.


## Usage
Plug'n'play :)
1. Plug a destination USB storage device (to which all files will be copied) **first**.
2. Plug a source USB storage device (from which all the files will be copied) **after** you've plugged a destination device.
3. Wait until an activity LED on any of your source/desitination devices stops blinking (for now it's the only way to determine when the copy process has stopped).


## Limitations
- Can't inform a user about results of a copy operation and/or its status (running/failed/etc...).
- Works only with two simultaneously connected USB storage devices.
- Assumes that the first partition on the first plugged USB device is a **destination** device and it has name **/dev/sda1**.
- Assumes that the first partition on the second (and the last) plugged USB device is a **source** device and it has name **/dev/sdb1**.


## Installation

### Create required folders
1. Create a folder for the scripts (e.g.: **/opt/usb-disk-copy**):
```bash
sudo mkdir --parents /opt/usb-disk-copy
```
2. Create a folder for log files (e.g.: **/var/log/usb-disk-copy**):
```bash
sudo mkdir --parents /var/log/usb-disk-copy
```

### Place the scripts into the working folder
1. Copy files **usb-disk-copy.sh** and **usb-disk-copy-wrapper.sh** to the previously created folder **/opt/usb-disk-copy**:
```bash
sudo cp ./usb-disk-copy.sh ./usb-disk-copy-wrapper.sh /opt/usb-disk-copy
```
2. Grant **execute** permission on both files:
```bash
sudo chmod u=rwx,go=r /opt/usb-disk-copy/usb-disk-copy.sh /opt/usb-disk-copy/usb-disk-copy-wrapper.sh
```

### Setup a service that will do the job
Unfortunately, **udev** strictly limits amount of time for a script that is specified in 'RUN' section to coplete.
So it's necessary to offload all time-consuming logic to some kind of service. Fortunately, **systemd** has the simple solution for this:
1. Create a **systemd** service description file at **/etc/systemd/system/** (e.g.: **usb-disk-copy-@.service**)
```bash
sudo touch /etc/systemd/system/usb-disk-copy-@.service
```
2. Fill the description file with the following content:
```text
[Unit]
Description=USB disk copy service
BindTo=dev-%i.device

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'cd /opt/usb-disk-copy/ && ./usb-disk-copy-wrapper.sh > /var/log/usb-disk-copy/wrapper.log'
```
**NOTE**
**/opt/usb-disk-copy/** must point to the same directory where you have copied the scripts.
**/var/log/usb-disk-copy/** must point to an existing directory.
3. Reload systemd daemon
```bash
 sudo systemctl daemon-reload
```

### Setup an udev rule
1. Create an udev script file in **/etc/udev/rules.d/** (e.g.: **50-usb-disk.rules**):
```bash
sudo touch /etc/udev/rules.d/50-usb-disk.rules
```
2. Fill the rule file with the following content:
```bash
ACTION=="add", KERNEL=="sd*", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", RUN+="/bin/systemctl --no-block start usb-disk-copy-@%k.service"
```
3. Restart udev daemon and check if there's no error messages in your terminal.
```bash
sudo service udev restart
```
