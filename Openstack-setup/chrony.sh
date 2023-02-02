#!/bin/bash
# setup NTP Service
sudo apt install -y chrony

echo "[TASK 1] install crony"
echo "VALUE: $1"
if [ $1 = "yes" ];
then
  echo "this is controller "
  sudo echo "allow $2" >> /etc/chrony/chrony.conf
else
  echo "this is NOT controller "
  sudo sed -i 's/pool 2.debian.pool.ntp.org offline iburst/#pool 2.debian.pool.ntp.org offline iburst/g' /etc/chrony/chrony.conf
  sudo echo "server controller iburst" >> /etc/chrony/chrony.conf

fi

sudo service chrony restart

# echo "[TASK 2] Update install openstack software"
# sudo apt install software-properties-common -y
# sudo add-apt-repository cloud-archive:zed
# sudo apt update && apt dist-upgrade -y
# sudo apt install python3-openstackclient -y

