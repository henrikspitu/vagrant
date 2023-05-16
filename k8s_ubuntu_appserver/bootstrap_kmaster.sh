# #!/bin/bash


echo "[Master TASK 1] Initialize control plane"

sudo lsmod | grep br_netfilter
sudo systemctl enable kubelet
sudo kubeadm config images pull
sudo kubeadm config images pull --cri-socket /run/containerd/containerd.soc


sudo kubeadm init --apiserver-advertise-address=$1 --upload-certs --cri-socket /run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16 


# Copy Kube admin config
echo "[Master TASK 2] Copy kube admin config to Vagrant user .kube directory"
sudo mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
sudo mkdir /home/hspo/.kube
sudo cp /etc/kubernetes/admin.conf /home/hspo/.kube/config
sudo chown -R hspo:hspo /home/hspo/.kube
sudo mkdir /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config


echo "[Master TASK 3] clustewr info"
sudo kubectl cluster-info



# Generate Cluster join commandk
echo "[Master TASK 4] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command --kubeconfig=/home/vagrant/.kube/config > /home/vagrant/joincluster.sh
sudo chown vagrant:vagrant /home/vagrant/joincluster.sh
sudo sleep 10:



# Deploy flannel network
echo "[Master TASK 5] Deploy Flannel network"
sudo  kubectl apply -f kube-flannel.yaml


sudo sleep 20:

sudo kubectl cluster-info
sudo kubectl get pods -n kube-flannel


echo "[Master TASK 6] get info"
kubectl get nodes -o wide
sudo kubectl get pods --all-namespaces


# Install helm
echo "[Master TASK 7] install helm"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


 
# Install MetalLB
echo "[Master TASK 8] apply MetalLB"
sudo helm repo add metallb https://metallb.github.io/metallb
sudo helm repo update
sudo helm install metallb metallb/metallb --create-namespace --namespace metallb-system


# NOTE: This can ONLy be done once a App Node have joined
#sudo kubectl apply -f /home/vagrant/files/metallb/ipAddressPool.yaml




# install ingress controller
echo "[Master TASK 9] install ingress controller"
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --create-namespace --namespace ingress-nginx





# install kubernetes dashboard
echo "[Master TASK 10] install  kubernetes dashboard"
VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)
echo $VER
wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
sudo kubectl apply -f kubernetes-dashboard.yaml
sudo kubectl apply -f /home/vagrant/files/dashboard/dashboard.yaml
sudo kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'

sudo kubectl -n kubernetes-dashboard create token admin-user >  /home/vagrant/dashboard-token.sh



echo "REMEMBER /home/vagrant/files/metallb/ipAddressPool.yaml need to be run after first add node have joined"


# install nfs provisioner
sudo helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

sudo helm install nfs-provisioner-01 nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.1.20 --set nfs.path=/data/k8s --set storageClass.defaultClass=true --set replicaCount=1 --set storageClass.name=nfs-01 --set storageClass.provisionerName=nfs-provisioner-01 --create-namespace --namespace  nfs-provisioner