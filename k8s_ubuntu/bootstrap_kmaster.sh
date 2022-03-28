#!/bin/bash

# setup hspo
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

echo "[TASK 1] disable swap"
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[TASK 2] fix cgroup-driver"
sudo cat <<EOT >> /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOT
sudo systemctl daemon-reload
sudo sleep 5
sudo systemctl restart docker
sudo sleep 5
sudo systemctl restart kubelet
sudo sleep 5

# Initialize Kubernetes
echo "[TASK 3] Initialize Kubernetes Cluster"
# default CIDER for flannel (10.244.0.0/16) 
sudo kubeadm init --apiserver-advertise-address=192.168.86.100 --pod-network-cidr=10.244.0.0/16  >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK 4] Copy kube admin config to Vagrant user .kube directory"
sudo mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
sudo mkdir /home/hspo/.kube
sudo cp /etc/kubernetes/admin.conf /home/hspo/.kube/config
sudo chown -R hspo:hspo /home/hspo/.kube
sudo mkdir /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config

# Deploy flannel network
echo "[TASK 5] Deploy Flannel network"
su - vagrant -c "sudo kubectl apply -f kube-flannel.yaml"

# Generate Cluster join command
echo "[TASK 6] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command > /joincluster.sh


 
# Install MetalLB
 echo "[TASK 7] apply MetalLB"
sudo kubectl apply -f /home/vagrant/files/metallb/namespace.yaml
sudo kubectl apply -f /home/vagrant/files/metallb/configmap.yaml
sudo kubectl apply -f /home/vagrant/files/metallb/metallb.yaml

# Install helm
 echo "[TASK 8] install helm"
 curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
 sudo apt-get install apt-transport-https --yes
 echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
 sudo apt-get update
 sudo apt-get install helm
 sudo kubectl --namespace kube-system create sa tiller
 sudo kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller


# install kubernetes dashboard
echo "[TASK 9] install  kubernetes dashboard"
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml


