#!/bin/bash
if [ $USER == "pi" ]; then
  #echo "ipv4only" >> /etc/dhcpcd.conf
  #echo "noipv6" >> /etc/dhcpcd.conf
  grep -q -F 'ipv4only' /etc/dhcpcd.conf || sudo echo 'ipv4only' >> /etc/dhcpcd.conf
  grep -q -F 'noipv6' /etc/dhcpcd.conf || sudo echo 'noipv6' >> /etc/dhcpcd.conf
  sudo systemctl disable avahi-daemon.service
  sudo systemctl disable avahi-daemon.socket
  sudo systemctl stop avahi-daemon-service
  sudo systemctl stop avahi-daemon.socket
  sudo systemctl daemon-reload
  sudo systemctl restart dhcpcd.service
  echo "#done"
fi
exit 0