#!/bin/bash

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.86.56 openstack2.hspo.com


EOF

#setup hspo
echo "[TASK 0] Setup user hspo"
sudo useradd -m hspo -s /bin/bash
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo mkdir /home/hspo/workspace
sudo chown -R hspo:hspo /home/hspo/workspace
#sudo chsh -s /bin/bash hspo
sudo echo set nocompatible > /home/hspo/.vimrc
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
sudo echo "$1" >> /home/hspo/.ssh/id_rsa.pub
#sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo



# Install apt-transport-https pkg
echo "[TASK 1] Installing apps"
sudo apt-get update --fix-missing
sudo apt-get install --reinstall ca-certificates

apt-get install -y git
sudo git config --global user.email "hspo5master@hotmail.com"
sudo git config --global user.name "henrikspitu"
sudi git config --global http.postBuffer 10048576000

echo "[TASK 2] Setup Openstack"
sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo chmod +x /opt/stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

#sudo -u stack -i
sudo runuser stack -l -c 'git clone https://opendev.org/openstack/devstack && echo "cloned" ||  echo "clone failed"'
ls

sudo echo "[[local|localrc]]" >> /opt/stack/devstack/local.conf
sudo echo "ADMIN_PASSWORD=pass4Me" >> /opt/stack/devstack/local.conf
sudo echo "DATABASE_PASSWORD=\$ADMIN_PASSWORD" >> /opt/stack/devstack/local.conf
sudo echo "RABBIT_PASSWORD=\$ADMIN_PASSWORD" >> /opt/stack/devstack/local.conf
sudo echo "SERVICE_PASSWORD=\$ADMIN_PASSWORD" >> /opt/stack/devstack/local.conf
sudo echo "HOST_IP=$2" >> /opt/stack/devstack/local.conf
sudo runuser stack -l -c '/opt/stack/devstack/stack.sh'



