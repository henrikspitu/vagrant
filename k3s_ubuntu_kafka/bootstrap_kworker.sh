

MASTER_IP="$1"
WORKER_IP="$2"
TOKEN_FILE="$3"
NETWORK_INTERFACE="$4"


echo "Waiting for token file: ${TOKEN_FILE}"
while [ ! -s "${TOKEN_FILE}" ]; do
  sleep 2
done

JOIN_TOKEN="$(tr -d '\r' < "${TOKEN_FILE}")"

echo "[Worker TASK 1] Setup Worker Node"
echo "[Worker TASK 1] MASTER_IP: $MASTER_IP  WORKER_IP: $WORKER_IP JOIN_TOKEN : $JOIN_TOKEN NETWORK_INTERFACE: $NETWORK_INTERFACE"

curl -sfL https://get.k3s.io | sudo K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN="${JOIN_TOKEN}" INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP} --flannel-iface=${NETWORK_INTERFACE}" sh -


# curl -sfL https://get.k3s.io | sudo \
#   K3S_URL="https://192.168.1.150:6443" \
#   K3S_TOKEN="K10c496cc77119b80a422c682c2996a7420c7413ce84179da99b61e787d26d2b213::server:ccec9d05d95d61def241d0b73b1d5d1f" \
#   INSTALL_K3S_EXEC="agent --node-ip=192.168.1.151 --node-external-ip=192.168.1.151 --flannel-iface=eth1" \
#   sh -


#echo "[TASK 3] add server IP to kubelet $1"
#sudo sed -i 's/.*\/usr\/bin\/kubelet.*/ExecStart=\/usr\/bin\/kubelet --node-ip='"$2"' $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


# echo "args $1 $2 $3"
# # Join worker nodes to the Kubernetes cluster
# echo "[Worker TASK 1] get Join file from master "
# sudo apt-get  install -y sshpass >/dev/null 2>&1
# #sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.hspo.com:/joincluster.sh /joincluster.sh 2>/dev/null
# sudo sshpass -p "vagrant" scp -o StrictHostKeyChecking=no  vagrant@kmaster.sharks4it.com:/home/vagrant/joincluster.sh /home/vagrant/joincluster.sh
# sudo chown $(id -u):$(id -g) /home/vagrant/joincluster.sh
# sudo cat /home/vagrant/joincluster.sh
# sudo chmod +x /home/vagrant/joincluster.sh

# echo "[Worker TASK 2] Join node to Kubernetes Cluster"
# sudo bash /home/vagrant/joincluster.sh

# sudo sleep 20:
# if [ "$2" -eq "$3" ]; then
#     echo "last workernode call master"
#     sshpass -p 'vagrant' ssh vagrant@kmaster.sharks4it.com 'sudo kubectl apply -f /home/vagrant/files/metallb/ipAddressPool.yaml'
#     echo "install nginx"
#     sshpass -p 'vagrant' ssh vagrant@kmaster.sharks4it.com 'sudo helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --create-namespace --namespace ingress-nginx'


    

# fi



