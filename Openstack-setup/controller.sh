
echo "[TASK 1] install maria database" 
sudo apt install mariadb-server python3-pymysql -y


echo "[TASK 2] Configure database"
cat >>/etc/mysql/mariadb.conf.d/99-openstack.cnf<<EOF
[mysqld]
bind-address = $1
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF


sudo service mysql restart


mysql_secure_installation <<EOF
&
y
$3
$3
y
n
y
y
EOF



echo "[TASK 3] install rabbitmq-server"
sudo apt install rabbitmq-server -y
sudo rabbitmqctl add_user openstack $2
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"



echo "[TASK 4] install memcache"
sudo apt install memcached python-memcache -y

sudo sed -i 's/-l 127.0.0.1/-l '$1'/g' /etc/memcached.conf
sudo service memcached restart

echo "[TASK 5] configure etcd"
sudo groupadd --system etcd
sudo useradd --home-dir "/var/lib/etcd" --system --shell /bin/false -g etcd etcd
sudo mkdir -p /etc/etcd
sudo chown etcd:etcd /etc/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd


sudo rm -rf /tmp/etcd && mkdir -p /tmp/etcd
sudo curl -L https://github.com/coreos/etcd/releases/download/v3.2.7/etcd-v3.2.7-linux-amd64.tar.gz -o /tmp/etcd-v3.2.7-linux-amd64.tar.gz
sudo tar xzvf /tmp/etcd-v3.2.7-linux-amd64.tar.gz -C /tmp/etcd --strip-components=1
sudo cp /tmp/etcd/etcd /usr/bin/etcd
sudo cp /tmp/etcd/etcdctl /usr/bin/etcdctl


sudo cat >>/etc/etcd/etcd.conf.yml<<EOF
name: controller
data-dir: /var/lib/etcd
initial-cluster-state: 'new'
initial-cluster-token: 'etcd-cluster-01'
initial-cluster: controller=http://$1:2380
initial-advertise-peer-urls: http://$1:2380
advertise-client-urls: http://$1:2379
listen-peer-urls: http://0.0.0.0:2380
listen-client-urls: http://$1:2379
EOF


sudo cat >>/lib/systemd/system/etcd.service<<EOF
[Unit]
After=network.target
Description=etcd - highly-available key value store

[Service]
LimitNOFILE=65536
Restart=on-failure
Type=notify
ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf.yml
User=etcd

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable etcd
sudo systemctl start etcd 



echo "[TASK 6] setup keystone"

sudo mysql -e "CREATE DATABASE keystone"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$3'"

sudo apt install keystone apache2 libapache2-mod-wsgi crudini -y
sudo crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$3@controller/keystone
sudo crudini --set /etc/keystone/keystone.conf token provider fernet

sudo su -s /bin/sh -c "keystone-manage db_sync" keystone


sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password $3 --bootstrap-admin-url http://controller:5000/v3/ --bootstrap-internal-url http://controller:5000/v3/ --bootstrap-public-url http://controller:5000/v3/ --bootstrap-region-id RegionOne

sudo sed -i '$ a ServerName controller' /etc/apache2/apache2.conf

sudo service apache2 restart

echo "[TASK 7] create Client script files"

sudo cat >>/home/vagrant/admin-openrc<<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$3
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

sudo chmod +x /home/vagrant/admin-openrc

sudo cat >>/home/vagrant/demo-openrc<<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$3
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
sudo chmod +x /home/vagrant/demo-openrc

sudo . /home/vagrant/admin-openrc

sudo openstack token issue

echo "[TASK 8] Setup Keystone Resources"
sudo openstack project create --domain default --description "Service Project" service
sudo openstack project create --domain default --description "Demo Project" demo
sudo openstack user create --domain default --password $3 demo
sudo openstack role create user
sudo openstack role add --project demo --user demo user				


echo "[TASK 3] setup Glance"

sudo mysql -e "CREATE DATABASE glance"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$3'"
sudo openstack user create --domain default --password $3 glance
sudo openstack role add --project service --user glance admin
sudo openstack service create --name glance --description "OpenStack Image" image
sudo openstack endpoint create --region RegionOne image public http://controller:9292
sudo openstack endpoint create --region RegionOne image internal http://controller:9292
sudo openstack endpoint create --region RegionOne image admin http://controller:9292

sudo apt update -y	
sudo apt install glance -y	

sudo crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$3@controller/glance			
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller:11211
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken password $3
sudo crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
# Configure Glance to store Images on Local Filesystem							
sudo crudini --set /etc/glance/glance-api.conf glance_store stores "file,http"							
sudo crudini --set /etc/glance/glance-api.conf glance_store default_store file							
sudo crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

#glance registry
sudo crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$3@controller/glance
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
sudo crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $3
sudo crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

sudo su -s /bin/sh -c "glance-manage db_sync" glance			

sudo service glance-registry restart
sudo service glance-api restart

#sudo . /home/vagrant/admin-openrc
#sudo wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
#sudo openstack image create cirros3.5 --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public
#sudo openstack image list