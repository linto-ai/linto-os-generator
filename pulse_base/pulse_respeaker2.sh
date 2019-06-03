#!/bin/bash
apt-get -y install pulseaudio libpulse-dev pavucontrol

#audio config
echo "default-sample-rate = 16000" >> /etc/pulse/daemon.conf
echo "default-sample-format = s16le" >> /etc/pulse/daemon.conf
echo "default-sample-channels = 1" >> /etc/pulse/daemon.conf
cd /home/pi
git clone https://github.com/respeaker/seeed-voicecard
cd seeed-voicecard/
sudo ./install.sh