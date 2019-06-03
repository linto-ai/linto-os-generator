#/bin/bash
#fix ssh keys perms
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y git

sudo chown -R pi /home/pi

if [ -f /home/pi/.ssh/id_rsa ]; then
  chmod 600 /home/pi/.ssh/id_rsa
fi

if [ -f /home/pi/.ssh/id_rsa.pub ]; then
  chmod 600 /home/pi/.ssh/id_rsa.pub
fi

if [ -f /home/pi/.ssh/config ]; then
  chmod 600 /home/pi/.ssh/config
fi

sed /etc/systemd/system/autologin@.service -i -e "s#^ExecStart=-/sbin/agetty --autologin [^[:space:]]*#ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options \"-f pi\" %I $TERM#"