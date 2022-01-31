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
sudo kubeadm init --apiserver-advertise-address=192.29.16.50 --pod-network-cidr=192.168.0.0/16  >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK 4] Copy kube admin config to Vagrant user .kube directory"
sudo mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
sudo mkdir /home/hspo/.kube
sudo cp /etc/kubernetes/admin.conf /home/hspo/.kube/config
chown -R hspo:hspo /home/hspo/.kube

# Deploy flannel network
echo "[TASK 5] Deploy caliso network"
su - vagrant -c "sudo kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml"

# Generate Cluster join command
echo "[TASK 6] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command > /joincluster.sh

# Install helm
# echo "[TASK 7] install helm"
# curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
# sudo apt-get install apt-transport-https --yes
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# sudo apt-get update
# sudo apt-get install helm
# sudo kubectl --namespace kube-system create sa tiller
# sudo kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller



