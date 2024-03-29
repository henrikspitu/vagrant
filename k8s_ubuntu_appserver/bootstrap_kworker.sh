


#echo "[TASK 3] add server IP to kubelet $1"
#sudo sed -i 's/.*\/usr\/bin\/kubelet.*/ExecStart=\/usr\/bin\/kubelet --node-ip='"$2"' $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


echo "args $1 $2 $3"
# Join worker nodes to the Kubernetes cluster
echo "[Worker TASK 1] get Join file from master "
sudo apt-get  install -y sshpass >/dev/null 2>&1
#sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.hspo.com:/joincluster.sh /joincluster.sh 2>/dev/null
sudo sshpass -p "vagrant" scp -o StrictHostKeyChecking=no  vagrant@kmaster.sharks4it.com:/home/vagrant/joincluster.sh /home/vagrant/joincluster.sh
sudo chown $(id -u):$(id -g) /home/vagrant/joincluster.sh
sudo cat /home/vagrant/joincluster.sh
sudo chmod +x /home/vagrant/joincluster.sh

echo "[Worker TASK 2] Join node to Kubernetes Cluster"
sudo bash /home/vagrant/joincluster.sh

sudo sleep 20:
if [ "$2" -eq "$3" ]; then
    echo "last workernode call master"
    sshpass -p 'vagrant' ssh vagrant@kmaster.sharks4it.com 'sudo kubectl apply -f /home/vagrant/files/metallb/ipAddressPool.yaml'
    echo "install nginx"
    sshpass -p 'vagrant' ssh vagrant@kmaster.sharks4it.com 'sudo helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --create-namespace --namespace ingress-nginx'


    

fi



