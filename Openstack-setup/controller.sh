
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

# set for vagrant to run automation
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$3
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

echo "IS the ENV vars SET"
echo $OS_USERNAME

source /home/vagrant/admin-openrc

echo "IS the ENV vars SET NOW ?"
echo $OS_USERNAME
openstack token issue

echo "[TASK 8] Setup Keystone Resources"
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password $3 demo
openstack role create user
openstack role add --project demo --user demo user				

echo "Openstack commands done"

echo "[TASK 9] setup Glance"

sudo mysql -e "CREATE DATABASE glance"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$3'"
openstack user create --domain default --password $3 glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

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

source /home/vagrant/admin-openrc

sudo wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create cirros3.5 --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public
openstack image list


echo "[TASK 10] setup Nova"

sudo mysql -e "CREATE DATABASE nova_api"
sudo mysql -e "CREATE DATABASE nova"
sudo mysql -e "CREATE DATABASE nova_cell0"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$3'"

openstack user create --domain default --password $3 nova
openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

openstack user create --domain default --password $3 placement
openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

sudo apt install -y nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api

# Configure MySQL & RabbitMQ parameters in /etc/nova/nova.conf
sudo crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$3@controller/nova_api
sudo crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$3@controller/nova
sudo crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:$3@controller

#Configure Identity Service access
sudo crudini --set /etc/nova/nova.conf api auth_strategy keystone
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
sudo crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
sudo crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
sudo crudini --set /etc/nova/nova.conf keystone_authtoken username nova
sudo crudini --set /etc/nova/nova.conf keystone_authtoken password $3

#Configure support for Networking Service
sudo crudini --set /etc/nova/nova.conf DEFAULT my_ip $1
sudo crudini --set /etc/nova/nova.conf DEFAULT use _neutron True
sudo crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

#Configure vnc proxy on Controller Node
sudo crudini --set /etc/nova/nova.conf vnc enabled True
sudo crudini --set /etc/nova/nova.conf vnc vncserver_listen $1
sudo crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $1

#Configure Glance location
sudo crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292

# Configure Lock Path for Oslo Concurrency
sudo crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# Configure Placement API
sudo crudini --set /etc/nova/nova.conf placement os_region_name RegionOne
sudo crudini --set /etc/nova/nova.conf placement project_domain_name Default
sudo crudini --set /etc/nova/nova.conf placement project_name service
sudo crudini --set /etc/nova/nova.conf placement auth_type password
sudo crudini --set /etc/nova/nova.conf placement user_domain_name Default
sudo crudini --set /etc/nova/nova.conf placement auth_url http://controller:35357/v3
sudo crudini --set /etc/nova/nova.conf placement username placement
sudo crudini --set /etc/nova/nova.conf placement password $3

# Remove log_dir parameter in DEFAULT section
sudo crudini --del /etc/nova/nova.conf DEFAULT log_dir

sudo su -s /bin/sh -c "nova-manage api_db sync" nova

#Register cell0 Database
sudo su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

#Create cell1 Cell
sudo su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

#Populate nova Database
sudo su -s /bin/sh -c "nova-manage db sync" nova

# Verify configuration of Cells
sudo nova-manage cell_v2 list_cells

sudo service nova-api restart
sudo service nova-consoleauth restart
sudo service nova-scheduler restart
sudo service nova-conductor restart
sudo service nova-novncproxy restart

echo "Novo DONE on controller"