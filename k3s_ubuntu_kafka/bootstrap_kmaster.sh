# #!/bin/bash


MASTER_IP="$1"

echo "[Master TASK 1] Install k3s and create cluster"
echo "setup master using IP $MASTER_IP"
curl -sfL https://get.k3s.io | sudo sh -s - server --node-ip="${MASTER_IP}" --advertise-address="${MASTER_IP}" --write-kubeconfig-mode=644


echo "[Master TASK 2] verify installation"
sudo k3s kubectl get nodes

echo "[Master TASK 3] print Join Token"
sudo cat /var/lib/rancher/k3s/server/node-token

echo "[Master TASK 4] Install helm"
sudo apt-get update
sudo apt-get install -y curl gpg apt-transport-https
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm
helm version


# sudo lsmod | grep br_netfilter
# sudo systemctl enable kubelet
# sudo kubeadm config images pull
# sudo kubeadm config images pull --cri-socket /run/containerd/containerd.soc


# sudo kubeadm init --apiserver-advertise-address=$1 --upload-certs --cri-socket /run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16 


# # Copy Kube admin config
# echo "[Master TASK 2] Copy kube admin config to Vagrant user .kube directory"
# sudo mkdir /home/vagrant/.kube
# sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
# sudo chown -R vagrant:vagrant /home/vagrant/.kube
# sudo mkdir /home/hspo/.kube
# sudo cp /etc/kubernetes/admin.conf /home/hspo/.kube/config
# sudo chown -R hspo:hspo /home/hspo/.kube
# sudo mkdir /root/.kube
# sudo cp /etc/kubernetes/admin.conf /root/.kube/config


# echo "[Master TASK 3] clustewr info"
# sudo kubectl cluster-info



# # Generate Cluster join commandk
# echo "[Master TASK 4] Generate and save cluster join command to /joincluster.sh"
# sudo kubeadm token create --print-join-command --kubeconfig=/home/vagrant/.kube/config > /home/vagrant/joincluster.sh
# sudo chown vagrant:vagrant /home/vagrant/joincluster.sh
# sudo sleep 10:



# # Deploy flannel network
# echo "[Master TASK 5] Deploy Flannel network"
# sudo  kubectl apply -f kube-flannel.yaml


# sudo sleep 20:

# sudo kubectl cluster-info
# sudo kubectl get pods -n kube-flannel


# echo "[Master TASK 6] get info"
# kubectl get nodes -o wide
# sudo kubectl get pods --all-namespaces


# # Install helm
# echo "[Master TASK 7] install helm"
# curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
# sudo apt-get install apt-transport-https --yes
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# sudo apt-get update
# sudo apt-get install helm


 
# # Install MetalLB
# echo "[Master TASK 8] apply MetalLB"
# sudo helm repo add metallb https://metallb.github.io/metallb
# sudo helm repo update
# sudo helm install metallb metallb/metallb --create-namespace --namespace metallb-system


# # NOTE: This can ONLy be done once a App Node have joined
# #sudo kubectl apply -f /home/vagrant/files/metallb/ipAddressPool.yaml




# # # install ingress controller (Moved to last workernode)
# # echo "[Master TASK 9] install ingress controller"
# # helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --create-namespace --namespace ingress-nginx





# # install kubernetes dashboard
# echo "[Master TASK 10] install  kubernetes dashboard"
# wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
# sudo kubectl apply -f kubernetes-dashboard.yaml
# sudo kubectl apply -f /home/vagrant/files/dashboard/dashboard.yaml
# sudo kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'

# sudo kubectl -n kubernetes-dashboard create token admin-user >  /home/vagrant/dashboard-token.sh



# echo "REMEMBER /home/vagrant/files/metallb/ipAddressPool.yaml need to be run after first add node have joined"



# # install nfs provisioner
# echo "[Master TASK 11] install  nfs provider"
# sudo helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

# sudo helm install nfs-provisioner-01 nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.1.20 --set nfs.path=/data/k8s --set storageClass.defaultClass=true --set replicaCount=1 --set storageClass.name=nfs-01 --set storageClass.provisionerName=nfs-provisioner-01 --create-namespace --namespace  nfs-provisioner


# echo "[Master TASK 12] generate sharks4it tls certs"

# #chmod +x /home/vagrant/files/certs/create-certs.sh
# #./home/vagrant/files/certs/create-certs.sh


# #kubectl create secret generic sharks4it-tls --from-file=tls.key=/home/vagrant/tls-certs/sharks4it.key --from-file=tls.crt=/home/vagrant/tls-certs/sharks4it.crt --namespace kubernetes-dashboard