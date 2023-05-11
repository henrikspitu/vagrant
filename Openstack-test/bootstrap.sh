#!/bin/bash

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
$2 test



EOF

#setup hspo
echo "[TASK 0] Setup user hspo"
sudo useradd -m hspo -s /bin/bash
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo mkdir /home/hspo/workspace
sudo chown -R hspo:hspo /home/hspo/workspace
#sudo chsh -s /bin/bash hspo
sudo echo set nocompatible > /home/hspo/.vimrc
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
sudo echo "$1" >> /home/hspo/.ssh/id_rsa.pub
#sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo



# Install apt-transport-https pkg
echo "[TASK 1] Installing apps"
sudo apt-get update --fix-missing
sudo apt-get install --reinstall ca-certificates

apt-get install -y git
sudo git config --global user.email "hspo5master@hotmail.com"
sudo git config --global user.name "henrikspitu"
sudo git config --global http.postBuffer 10048576000


# #install openstack util
# sudo apt-get update  -y
# sudo apt-get install -y  glances
# sudo apt upgrade -y


# #!/bin/bash
# # setup NTP Service
# sudo apt install -y chrony

# echo "[TASK 3] Update /etc/chrony/chrony.conf file"
# cat >>/etc/chrony/chrony.conf<<EOF
# allow 10.0.0.0/24
# EOF

# sudo service chrony restart

# echo "[TASK 4] Update install openstack software"
# sudo apt install software-properties-common -y
# sudo add-apt-repository cloud-archive:zed
# sudo apt update && apt dist-upgrade -y
# sudo apt install nova-compute
# sudo apt install python3-openstackclient -y


# echo "[TASK 5] install maria software" 
# sudo apt install mariadb-server python3-pymysql -y


# echo "[TASK 6] Configure database"
# cat >>/etc/mysql/mariadb.conf.d/99-openstack.cnf<<EOF
# [mysqld]
# bind-address = $2
# default-storage-engine = innodb
# innodb_file_per_table = on
# max_connections = 4096
# collation-server = utf8_general_ci
# character-set-server = utf8
# EOF

# sudo service mysql restart


# mysql_secure_installation <<EOF
# n
# n
# n
# n
# y
# EOF


# echo "[TASK 7] install rabbitmq-server"
# sudo apt install rabbitmq-server -y
# sudo rabbitmqctl add_user openstack openstack
# sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# echo "[TASK 8] install memcache"
# sudo apt install memcached python3-memcache -y

# sudo sed -i 's/-l 127.0.0.1/-l '$2'/g' /etc/memcached.conf
# sudo service memcached restart

# echo "[TASK 9] setup etcd"
# sudo apt install etcd -y



# cat >>/etc/default/etcd<<EOF
# ETCD_NAME="test"
# ETCD_DATA_DIR="/var/lib/etcd"
# ETCD_INITIAL_CLUSTER_STATE="new"
# ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
# ETCD_INITIAL_CLUSTER="test=http://$2:2380"
# ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$2:2380"
# ETCD_ADVERTISE_CLIENT_URLS="http://$2:2379"
# ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
# ETCD_LISTEN_CLIENT_URLS="http://$2:2379"
# EOF

# sudo systemctl enable etcd
# sudo systemctl restart etcd


