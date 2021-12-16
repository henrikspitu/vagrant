#!/bin/bash
echo "KEY FILE $1"
sudo yum update
sudo yum install -y  dnsutils
sudo yum install -y curl
sudo apt-add-repository ppa:ansible/ansible -y
sudo yum update
sudo yum install -y ansible
sudo yum install git -y
sudo useradd -m hspo
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo