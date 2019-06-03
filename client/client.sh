#!/bin/bash

apt-get install -y mosquitto mosquitto-dev
echo "pid_file /var/run/mosquitto.pid" | sudo tee /etc/mosquitto/mosquitto.conf
cd /home/pi

echo "Installing Node dependancies"
apt-get install -y curl software-properties-common
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install nodejs

sudo -H -u pi bash -c "git clone https://github.com/linto-ai/linto-client.git"
cd linto-client
sudo -H -u pi bash -c "npm install"
exit