#!/bin/bash

#check we are root
if [ "$USER" != "root" ]; then
	echo "Script must be run as root"
	exit 1
fi

#fix rights
chown -R pi:pi /home/pi

chown -R root:root /lib/systemd/system/
chmod 644 /lib/systemd/system/systemd-udevd.service

chown -R root:root /etc/udev/rules.d/
chmod 644 /etc/udev/rules.d/11-usb-mount-drive.rules

#fix binaries right
if [ -f /usr/local/bin/expand.sh ]; then
  chmod +x /usr/local/bin/expand.sh
fi

if [ -f /usr/local/bin/defaultvolume.sh ]; then
  chmod +x /usr/local/bin/defaultvolume.sh
fi

if [ -f /usr/local/bin/waitforsoundcard.sh ]; then
  chmod +x /usr/local/bin/waitforsoundcard.sh
fi

#enable custom services here

if [ -f /etc/systemd/system/pulseaudio.service ]; then
  systemctl enable pulseaudio.service
fi

if [ -f /etc/systemd/system/pulseaudio.service ]; then
  systemctl enable linto-client.service
fi

#enable ssh . Important since raspbian update 11-2016, disabled by default !!!
if [ -f /etc/systemd/system/sshd.service ]; then
  systemctl enable ssh.service
fi

systemctl daemon-reload


#delete swap
apt-get remove dphys-swapfile
rm -f /var/swap

#change pi user password
whiptail --msgbox "You will now be asked to enter a new password for the pi user" 20 60 1
passwd pi &&
whiptail --msgbox "Password changed successfully" 20 60 1

#set time fuse
dpkg-reconfigure tzdata

#set locale
dpkg-reconfigure locales

#set keyboard
dpkg-reconfigure console-data

dpkg-reconfigure keyboard-configuration
