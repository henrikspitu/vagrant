#!/bin/bash
# setup NTP Service
sudo apt install -y chrony

echo "[TASK 1] Update /etc/chrony/chrony.conf file"
cat >>/etc/chrony/chrony.conf<<EOF
allow 10.0.0.0/24
EOF

sudo service chrony restart

echo "[TASK 2] Update install openstack software"
sudo apt install software-properties-common -y
sudo add-apt-repository cloud-archive:zed
sudo apt update && apt dist-upgrade -y
sudo apt install python3-openstackclient -y

