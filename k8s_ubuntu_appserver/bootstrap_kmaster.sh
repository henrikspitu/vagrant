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
sudo kubeadm token create --print-join-command --kubeconfig=/home/vagrant/.kube/config > /joincluster.sh
sudo chown vagrant:vagrant /joincluster.sh
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
MetalLB_RTAG=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')
echo $MetalLB_RTAG
wget https://raw.githubusercontent.com/metallb/metallb/v$MetalLB_RTAG/config/manifests/metallb-native.yaml
sudo kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
sudo kubectl apply -f metallb-native.yaml

#ISSUE
#sudo kubectl apply -f /home/vagrant/files/metallb/ipAddressPool.yaml


#sudo kubectl apply -f /home/vagrant/files/metallb/namespace.yaml
#sudo kubectl apply -f /home/vagrant/files/metallb/configmap.yaml
#sudo kubectl apply -f /home/vagrant/files/metallb/metallb.yaml


# # install ingress controller
# echo "[Master TASK 9] install ingress controller"
# controller_tag=$(curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d '"' -f 4)
# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/${controller_tag}/deploy/static/provider/baremetal/deploy.yaml
# mv deploy.yaml nginx-ingress-controller-deploy.yaml
# sudo kubectl apply -f nginx-ingress-controller-deploy.yaml




# # install kubernetes dashboard
# echo "[Master TASK ] install  kubernetes dashboard"
# VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)
# echo $VER
# wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
# sudo kubectl apply -f kubernetes-dashboard.yaml


# EOT
# sudo systemctl daemon-reload
# sudo sleep 5
# sudo systemctl restart docker
# sudo sleep 5
# sudo systemctl restart kubelet
# sudo sleep 5

# # Initialize Kubernetes
# echo "[Master TASK 2] Initialize Kubernetes Cluster"
# # default CIDER for flannel (10.244.0.0/16) 
# sudo kubeadm init --apiserver-advertise-address=192.168.1.150 --pod-network-cidr=10.244.0.0/16  >> /root/kubeinit.log 2>/dev/null

# # Copy Kube admin config
# echo "[Master TASK 4] Copy kube admin config to Vagrant user .kube directory"
# sudo mkdir /home/vagrant/.kube
# sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
# sudo chown -R vagrant:vagrant /home/vagrant/.kube
# sudo mkdir /home/hspo/.kube
# sudo cp /etc/kubernetes/admin.conf /home/hspo/.kube/config
# sudo chown -R hspo:hspo /home/hspo/.kube
# sudo mkdir /root/.kube
# sudo cp /etc/kubernetes/admin.conf /root/.kube/config

# # Deploy flannel network
# echo "[Master TASK 5] Deploy Flannel network"
# sudo  kubectl apply -f kube-flannel.yaml

# # Generate Cluster join commandk
# echo "[Master TASK 6] Generate and save cluster join command to /joincluster.sh"
# sudo kubeadm token create --print-join-command --kubeconfig=/home/vagrant/.kube/config > /joincluster.sh
# sudo chown vagrant:vagrant /joincluster.sh
# sudo sleep 10:

# # Install helm
#  echo "[Master TASK 7] install helm"
#  curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
#  sudo apt-get install apt-transport-https --yes
#  echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
#  sudo apt-get update
#  sudo apt-get install helm
#  sudo kubectl --namespace kube-system create sa tiller
#  sudo kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

 
# # Install MetalLB
#  echo "[Master TASK 8] apply MetalLB"
# sudo kubectl apply -f /home/vagrant/files/metallb/namespace.yaml
# sudo kubectl apply -f /home/vagrant/files/metallb/configmap.yaml
# sudo kubectl apply -f /home/vagrant/files/metallb/metallb.yaml

# # install kubernetes dashboard
# echo "[Master TASK 9] install  kubernetes dashboard"
# sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml



