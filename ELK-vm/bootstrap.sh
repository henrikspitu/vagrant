#!/bin/bash
echo "KEY FILE $1"
sudo apt update
sudo apt install -y  dnsutils
sudo apt install -y curl
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install -y ansible
sudo apt install git -y
sudo apt install docker -y
sudo useradd -m hspo
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo mkdir /home/hspo/workspace
sudo chown -R hspo:hspo /home/hspo/workspace
sudo chsh -s /bin/bash hspo
sudo echo set nocompatible > /home/hspo/.vimrc
sudo chsh -s /bin/bash hspo
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
#sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo
sudo useradd -m ansible -p ansible
sudo mkdir /home/ansible/.ssh
sudo chown -R ansible:ansible /home/ansible/.ssh
sudo echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add --passphrase "password"
sudo apt-get install apt-transport-https
sudo echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch
sudo apt install openjdk-8-jre-headless
sudo apt-get update
sudo apt-get install logstash

sudo  echo "ALL DONE"