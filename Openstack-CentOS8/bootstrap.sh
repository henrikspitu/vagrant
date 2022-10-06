#!/bin/bash

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.86.55 openstack.hspo.com


EOF

#setup hspo
echo "[TASK 0] Setup user hspo"
sudo useradd -m hspo -s /bin/bash
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo mkdir /home/hspo/workspace
sudo chown -R hspo:hspo /home/hspo/workspace
sudo chsh -s /bin/bash hspo
sudo echo set nocompatible > /home/hspo/.vimrc
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
sudo echo "$1" >> /home/hspo/.ssh/id_rsa.pub
#sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo



# Install apt-transport-https pkg
echo "[TASK 1] Installing apps"
sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum update -y
sudo yum install -y wget
sudo yum install -y unzip
sudo yum install -y redhat-lsb-core
#sudo yum install -y sipcalc
#sudo yum install -y w3m
#sudo yum install -y ipvsadm
#sudo yum install -y sshpass
sudo yum install -y git
sudo yum install -y net-tools
sudo git config --global user.email "hspo5master@hotmail.com"
sudo git config --global user.name "henrikspitu"

# install time service so timestamp in logs & metricbeat are correct
#sudo yum install -y ntp
#sudo yum install -y ntpdate
#sudo ntpdate -y ntp.ubuntu.com
#sudo yum update


# Update vagrant user's bashrc file
#echo "export TERM=xterm" >> /etc/bashrc

# install openstack
#sudo echo "LANG=en_US.utf-8" >> /etc/environment
#sudo echo "LC_ALL=en_US.utf-8" >> /etc/environment
#sudo systemctl disable firewalld

#sudo systemctl stop NetworkManager
#sudo systemctl disable NetworkManager
#sudo systemctl start network

# Disable selinux
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config



