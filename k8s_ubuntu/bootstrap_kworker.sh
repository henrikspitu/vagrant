#!/bin/bash
echo "[TASK 1] setup hspo"
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


echo "[TASK 2] disable swap"
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[TASK 2] fix cgroup-driver"
sudo cat <<EOT >> /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOT

#echo "[TASK 3] add server IP to kubelet $2"
#sudo sed -i 's/.*\/usr\/bin\/kubelet.*/ExecStart=\/usr\/bin\/kubelet --node-ip='"$2"' $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload
sudo sleep 5
sudo systemctl restart docker
sudo sleep 5
sudo systemctl restart kubelet
sudo sleep 5


# Join worker nodes to the Kubernetes cluster
echo "[TASK 4] Join node to Kubernetes Cluster"
sudo apt-get  install -y sshpass >/dev/null 2>&1
#sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.hspo.com:/joincluster.sh /joincluster.sh 2>/dev/null
sudo sshpass -p "kubeadmin" scp -o StrictHostKeyChecking=no kmaster.hspo.com:/joincluster.sh /joincluster.sh
sudo bash /joincluster.sh >/dev/null 2>&1

echo "[TASK 5] set ELK permissions on mount"
sudo chown -R 1000:1000 /mnt/data
