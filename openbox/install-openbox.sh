#!/bin/bash
#run as root
uname -a
echo "./install-openbox.sh starting."

###########################################################
# update
###########################################################
#apt-get update

###########################################################
# GUI APPS
###########################################################
apt-get install -y xinit
apt-get install -y openbox

# For xset
apt-get install -y x11-xserver-utils

sudo dkpg --configure -a

#iceweasel kiosk
#apt-get install -y iceweasel

#chromium kiosk
# if grep -q "http://dl.bintray.com/kusti8/chromium-rpi" /etc/apt/sources.list; then
#   sudo apt-get update
#   sudo apt-get install chromium-browser -y
# else
#   wget -qO - http://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -
#   echo "deb http://dl.bintray.com/kusti8/chromium-rpi jessie main" | sudo tee -a /etc/apt/sources.list
#   sudo apt-get update
#   sudo apt-get install chromium-browser -y
# fi

###########################################################
# GUI CONFIG
###########################################################
#console autologin
systemctl set-default multi-user.target
ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service

#window manager openbox
apt-get install -y openbox

# Removes "AutoLogin terminal"
sed /etc/systemd/system/autologin@.service -i -e "s#^ExecStart=-/sbin/agetty --autologin [^[:space:]]*#ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options \"-f pi\" %I $TERM#"

# Boot Theme with plymouth
apt-get install -y plymouth-themes
plymouth-set-default-theme -R spinfinity

###########################################################
#verrouillage maj pasquets sensibles
###########################################################

echo "**************************************"
echo "./install-gui_script.sh done."
echo "**************************************"
