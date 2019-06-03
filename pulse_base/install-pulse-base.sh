#!/bin/bash

echo "./install-pulse.sh starting."
if [ $(id -u) -ne 0 ]; then
	echo "Ce script doit etre lance en root"
	exit 1
fi

echo "install and configure pulseaudio"
echo "Creating pulse user..."

groupadd --system pulse
groupadd --system pulse-access
useradd --system -g pulse -G audio -d /var/run/pulse -m pulse
usermod -G video,pulse-access pi

mkdir -p /etc/conf.d
touch /etc/conf.d/pulseaudio

echo "installing pulseaudio package"
apt-get update
apt-get install -y pulseaudio libpulse-dev
# apt-mark hold pulseaudio

echo "Creating configuration files"
if [ ! -f /etc/pulse/client.conf.default ]; then
  mv /etc/pulse/client.conf /etc/pulse/client.conf.default
fi
cat <<EOT > /etc/pulse/client.conf
default-server = /var/run/pulse/native
autospawn = no
EOT
if [ ! -f /etc/pulse/system.pa.default ]; then
  mv /etc/pulse/system.pa /etc/pulse/system.pa.default
fi
cat <<EOT >/etc/pulse/system.pa
load-module module-udev-detect
load-module module-native-protocol-unix auth-anonymous=1
load-module module-always-sink
EOT

# if [ ! -f /etc/pulse/daemon.conf.default ]; then
#   mv /etc/pulse/daemon.conf /etc/pulse/daemon.conf.default
# fi
# cat <<EOT > /etc/pulse/daemon.conf
# resample-method =  ffmpeg
# enable-remixing = no
# enable-lfe-remixing = no
# default-sample-format = s16le
# default-sample-rate = 16000
# alternate-sample-rate = 44100
# default-sample-channels = 1
# EOT

# echo "Configuring asound.conf"
touch /etc/asound.conf
cat <<EOT > /etc/asound.conf
pcm.pulse {
 type pulse
}
ctl.pulse {
 type pulse
}
pcm.!default {
 type pulse
}
ctl.!default {
 type pulse
}
EOT