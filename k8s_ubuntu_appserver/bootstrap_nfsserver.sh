


#echo "[TASK 3] add server IP to kubelet $1"
#sudo sed -i 's/.*\/usr\/bin\/kubelet.*/ExecStart=\/usr\/bin\/kubelet --node-ip='"$2"' $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf



# setup NFS
echo "[nfs TASK 1] setup nfs "
sudo sudo apt update
sudo sudo apt install nfs-kernel-server -y

sudo cat >>/etc/idmapd.conf<<EOF
Domain = sharks4it.com 
EOF


# sudo cat >>/etc/exports<<EOF
# /data/k8s/ 192.168.1.150(rw,no_root_squash)
# /data/k8s/ 192.168.1.151(rw,no_root_squash)
# /data/k8s/ 192.168.1.152(rw,no_root_squash)
# /data/k8s/ 192.168.1.153(rw,no_root_squash)
# EOF

sudo exportfs -a