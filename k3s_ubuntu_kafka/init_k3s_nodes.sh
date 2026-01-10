#!/bin/bash

echo "[K3s TASK 1] Disable Swap"
sudo swapoff -a
sudo sed -i.bak '/\sswap\s/s/^\(.*\)$/#\1/g' /etc/fstab


echo "[K3s TASK 2] update packages"
sudo apt-get update
sudo apt-get install -y curl




# # Update hosts file
# echo "[Init TASK 1] Install kubelet, kubeadm and kubectl"
# curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# sudo apt update
# sudo apt install wget curl vim git kubelet kubeadm kubectl -y
# sudo apt-mark hold kubelet kubeadm kubectl

# echo "[Init TASK 2] Verify Installation"
# kubectl version --client && kubeadm version


# echo "[Init TASK 3] disable swap"
# sudo swapoff -a 
# sudo sed -i '/swap/d' /etc/fstab
# sudo mount -a

# echo "[Init TASK 4] VERIFY disable swap"
# sudo free -h

# echo "[Init TASK 5] ENABLE KERNEL MODULES"
# sudo modprobe overlay
# sudo modprobe br_netfilter

# sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# net.ipv4.ip_forward = 1
# EOF

# sudo sysctl --system

# echo "[Init TASK 6] Setup Containerd"

# sudo tee /etc/modules-load.d/k8s.conf <<EOF
# overlay
# br_netfilter
# EOF

# sudo modprobe overlay
# sudo modprobe br_netfilter

# sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# net.ipv4.ip_forward = 1
# EOF

# sudo sysctl --system

# sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# sudo apt update
# sudo apt install -y containerd.io

# sudo su -
# mkdir -p /etc/containerd
# containerd config default>/etc/containerd/config.toml


# echo "[Init TASK 6.1] Systemd_cgroup to true"

# sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# sudo systemctl restart containerd
# sudo systemctl enable containerd

# sudo systemctl status containerd