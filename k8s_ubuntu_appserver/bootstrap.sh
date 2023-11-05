#!/bin/bash

# Update hosts file
echo "[Bootstrap TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.1.150 kmaster.sharks4it.com kmaster
192.168.1.151 kworker1.sharks4it.com kworker1
192.168.1.152 kworker2.sharks4it.com kworker2
192.168.1.153 kworker2.sharks4it.com kworker3
192.168.1.20  nfsserer.sharks4it.com  nfsserver



EOF


# setup hspo
echo "[Bootstrap TASK 2] Setup user hspo"
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

echo "[Bootstrap TASK 3] update Packages"
sudo apt update
sudo apt -y full-upgrade
echo "REBOOT SREVER"


echo "[Bootstrap TASK 4] install nfs util"
sudo apt-get install nfs-common nfs-kernel-server -y


echo "[Bootstrap TASK 1] Update nfs permissions list"
cat >>/etc/exports<<EOF
/data/k8s/ 192.168.1.150(rw,no_root_squash)
/data/k8s/ 192.168.1.151(rw,no_root_squash)
/data/k8s/ 192.168.1.152(rw,no_root_squash)
/data/k8s/ 192.168.1.153(rw,no_root_squash)

EOF




# # install time service so timestamp in logs & metricbeat are correct
# sudo apt install ntp
# sudo apt install ntpdate
# sudo ntpdate ntp.ubuntu.com


# # Disable swap
# echo "[ Bootstrap TASK 1] Disable and turn off SWAP"
# sed -i '/swap/d' /etc/fstab
# swapoff -a

# DOCKER IS INSTALLED DIFFERENTLY
# echo "[Bootstrap TASK 2] Install docker container engine"
# sudo apt-get update -y
# sudo apt-get install ca-certificates curl gnupg -y
# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg
# echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# echo "Install docker engine packages"
# sudo apt-get update
# sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y



# echo "[Bootstrap TASK 3] fix cgroup-driver"
# sudo cat <<EOT >> /etc/docker/daemon.json
# {
#     "exec-opts": ["native.cgroupdriver=systemd"]
# }

# EOT

# echo "[Bootstrap TASK 3.1] containered  bugfix"
# sudo rm /etc/containerd/config.toml
# sudo systemctl restart containerd


# sudo systemctl daemon-reload
# sudo sleep 5
# sudo systemctl restart docker
# # sudo sleep 5

# echo "[Bootstrap TASK 3] Install kubernetes"
# sudo apt-get install -y apt-transport-https ca-certificates curlvi 
# sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# sudo apt-get update
# sudo apt-get install -y kubelet kubeadm kubectl -y


#sudo apt-mark hold kubelet kubeadm kubectl
# # Add sysctl settings
# echo "[TASK 6] Add sysctl settings"
# cat >>/etc/sysctl.d/kubernetes.conf<<EOF
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# EOF
# sysctl --system >/dev/null 2>&1


# Install apt-transport-https pkg
# echo "[TASK 8] Installing apt-transport-https pkg"
# sudo apt update && apt install -y apt-transport-https curl
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# sudo apt install -y sipcalc
# sudo apt install -y w3m
# sudo apt install -y ipvsadm

# # Add he kubernetes sources list into the sources.list directory
# cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
# deb https://apt.kubernetes.io/ kubernetes-xenial main
# EOF

# ls -ltr /etc/apt/sources.list.d/kubernetes.list

# apt update -y

# # Install Kubernetes
# echo "[TASK 9] Install Kubernetes kubeadm, kubelet and kubectl"
# apt install -y kubelet kubeadm kubectl

# # Start and Enable kubelet service
# echo "[TASK 10] Enable and start kubelet service"
# systemctl enable kubelet >/dev/null 2>&1
# systemctl start kubelet >/dev/null 2>&1

# # Enable ssh password authentication
# echo "[TASK 11] Enable ssh password authentication"
# sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# systemctl restart sshd

# # Set Root password
# echo "[TASK 12] Set root password"
# echo -e "kubeadmin\nkubeadmin" | passwd root
# echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# # Update vagrant user's bashrc file
# echo "export TERM=xterm" >> /etc/bashrc
