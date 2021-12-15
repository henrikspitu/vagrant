#!/bin/bash
echo "KEY FILE $1"
sudo apt-get update
sudo apt-get install -y  dnsutils
sudo apt-get install -y curl
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update
sudo apt-get install -y ansible
sudo apt-get install xauth
sudo sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="dk"/g' /etc/default/keyboard
sudo useradd -m hspo
usermod -aG sudo hspo
sudo mkdir /home/hspo/.ssh
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo