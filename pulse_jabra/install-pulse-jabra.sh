#/bin/bash

# echo "./install-pulse.sh starting."
# if [ $(id -u) -ne 0 ]; then
# 	echo "Ce script doit etre lance en root"
# 	exit 1
# fi

# echo "install and configure pulseaudio"
# echo "Creating pulse user..."
# useradd pulse
# usermod -G audio pulse libpulse-dev pavucontrol

#  mkdir -p /etc/conf.d
#  touch /etc/conf.d/pulseaudio

# echo "installing pulseaudio package"
# apt-get install pulseaudio

# apt-mark hold pulseaudio

# echo "Creating configuration files"
# if [ ! -f /etc/pulse/system.pa.default ]; then
#   mv /etc/pulse/system.pa /etc/pulse/system.pa.default
# fi
# cat <<EOT >/etc/pulse/system.pa
# load-module module-udev-detect
# load-module module-native-protocol-unix auth-anonymous=1
# load-module module-always-sink
# EOT

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

# if [ ! -f /etc/pulse/client.conf ]; then
#   mv /etc/pulse/client.conf /etc/pulse/client.conf.default
# fi
# cat <<EOT > /etc/pulse/client.conf
# autospawn = no
# EOT

# echo "Configuring asound.conf"
# touch /etc/asound.conf
# cat <<EOT > /etc/asound.conf PULSEAUDIO
# pcm.pulse {
#  type pulse
# }
# ctl.pulse {
#  type pulse
# }
# pcm.!default {
#  type pulse
# }
# ctl.!default {
#  type pulse
# }
# EOT

#setting default source
#echo "default-source = alsa_input.usb-0b0e_Jabra_Speak_710_501AA5D64DE7-00.analog-mono" >> /etc/pulse/client.conf #audio config for Jabra
#secho "default-sink = alsa_output.usb-0b0e_Jabra_Speak_710_501AA5D64DE7-00.analog-stereo" >> /etc/pulse/client.conf #audio config for Jabra
#dependances :
apt-get -y install pulseaudio libpulse-dev pavucontrol

#audio config
echo "default-sample-rate = 16000" >> /etc/pulse/daemon.conf
echo "default-sample-format = s16le" >> /etc/pulse/daemon.conf
echo "default-sample-channels = 1" >> /etc/pulse/daemon.conf
#setting default source
#echo "default-source = alsa_input.usb-0b0e_Jabra_Speak_710_501AA5D64DE7-00.analog-mono" >> /etc/pulse/client.conf #audio config for Jabra
#secho "default-sink = alsa_output.usb-0b0e_Jabra_Speak_710_501AA5D64DE7-00.analog-stereo" >> /etc/pulse/client.conf #audio config for Jabra
