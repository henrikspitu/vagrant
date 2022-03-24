#!/bin/bash

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.86.51 dnsclient.hspo.com

EOF

setup hspo
echo "[TASK 0] Setup user hspo"
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

# Install apt-transport-https pkg
echo "[TASK 1] Installing apps"


sudo apt-get install -y sipcalc
sudo apt-get install -y w3m
sudo apt-get install -y ipvsadm
sudo apt-get install -y sshpass
sudo apt-get install -y git
sudo git config --global user.email "hspo5master@hotmail.com"
sudo git config --global user.name "henrikspitu"
# install time service so timestamp in logs & metricbeat are correct
sudo apt-get install -y ntp
sudo apt-get install -y ntpdate
sudo ntpdate -y ntp.ubuntu.com

echo "[TASK 2] Installing apps"
apt-get update -y
sudo apt install -y apache2

sudo mkdir /var/www/hspo

 sudo cp /home/vagrant/files/index.html /var/www/html/index.html

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc
