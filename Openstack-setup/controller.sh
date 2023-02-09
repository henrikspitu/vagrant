
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

echo "[TASK 11] setup Neutron"


sudo mysql -e "CREATE DATABASE neutron"
sudo mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$3'"

source /home/vagrant/admin-openrc
openstack user create --domain default --password $3 neutron
openstack role add --project service --user neutron admin

# Create Neutron Service and Endpoints
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

sudo apt install -y neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent  neutron-metadata-agent

#Configure SQL Database and RabbitMQ access for Neutron
sudo crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$3@controller/neutron
sudo crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$3@controller

# Enable the Modular Layer 2 (ML2) plug-in, router service, and overlapping IP addresses
sudo crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
sudo crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
sudo crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true

sudo crudini --set /etc/neutron/neutron.conf api auth_strategy keystone
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
sudo crudini --set /etc/neutron/neutron.conf keystone_authtoken password $3

#"Configure Networking to notify Compute of network topology changes"
sudo crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
sudo crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

#Configure Nova access
sudo crudini --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
sudo crudini --set /etc/neutron/neutron.conf nova auth_type password
sudo crudini --set /etc/neutron/neutron.conf nova project_domain_name default
sudo crudini --set /etc/neutron/neutron.conf nova user_domain_name default
sudo crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
sudo crudini --set /etc/neutron/neutron.conf nova project_name service
sudo crudini --set /etc/neutron/neutron.conf nova username nova
sudo crudini --set /etc/neutron/neutron.conf nova password $3

# Enable flat, VLAN and VXLAN Networks
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
# Enable VXLAN Self-service Networks
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
# Enable Linux Bridge and L2Population mechanisms
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
# Enable Port Security Extenstion Driver
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
# Configure provider Virtual Network as flat Network
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
# Configure VXLAN Network Identifier Range for Self-service Networks
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
# Enable ipset to increase efficiency of Security Group Rules
sudo crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

# Configure provider Virtual Network mapping to Physical Interface
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth3
# Enable VXLAN for Self-service Networks, configure IP address of the Management Interface handling VXLAN traffic
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $1
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
# Enable security groups and configure the Linux bridge iptables firewall driver
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
sudo crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

sudo crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

# Configure the DHCP Agent
sudo crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
sudo crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
sudo crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

sudo crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
sudo crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret openstack

sudo crudini --set /etc/nova/nova.conf neutron url http://controller:9696
sudo crudini --set /etc/nova/nova.conf neutron auth_url http://controller:35357
sudo crudini --set /etc/nova/nova.conf neutron auth_type password
sudo crudini --set /etc/nova/nova.conf neutron project_domain_name default
sudo crudini --set /etc/nova/nova.conf neutron user_domain_name default
sudo crudini --set /etc/nova/nova.conf neutron region_name RegionOne
sudo crudini --set /etc/nova/nova.conf neutron project_name service
sudo crudini --set /etc/nova/nova.conf neutron username neutron
sudo crudini --set /etc/nova/nova.conf neutron password $3
sudo crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
sudo crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret openstack

sudo -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

sudo service nova-api restart
sudo service neutron-server restart
sudo service neutron-linuxbridge-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-metadata-agent restart
sudo service neutron-l3-agent restart

echo "Neutron DONE on controller"


echo "[TASK 11] setup Cinder"

sudo mysql -e "CREATE DATABASE cinder"
sudo mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$3'"
sudo mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$3'"

openstack user create --domain default --password $3 cinder		
openstack role add --project service --user cinder admin

openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

sudo apt install -y cinder-api cinder-scheduler

crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$3@controller/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:$3@controller

crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password $3

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip $1
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

sudo -s /bin/sh -c "cinder-manage db sync" cinder			

crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne					

service nova-api restart
service cinder-scheduler restart	
service apache2 restart

echo "[TASK 12] setup horizon"
sudo apt install -y openstack-dashboard

# replace host name


sudo sed -i 's/ OPENSTACK_HOST = "127.0.0.1"/ OPENSTACK_HOST = "controller" /g' /etc/openstack-dashboard/local_settings.py
sudo sed -i "s/#SESSION_COOKIE_SECURE = True/SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/g" /etc/openstack-dashboard/local_settings.py

sudo sed -i 's/ 127.0.0.1:11211/ controller:11211 /g' /etc/openstack-dashboard/local_settings.py
sudo sed -i  's/127.0.0.1/controller/g' /etc/openstack-dashboard/local_settings.py

# modify version in: OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
sudo sed -i  's/v2.0/v3/g' /etc/openstack-dashboard/local_settings.py

sudo sed -i  's/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g' /etc/openstack-dashboard/local_settings.py

# multiple lines to replace
#https://linuxhint.com/use-sed-replace-multiple-lines/
# sudo sed -i  's/#OPENSTACK_API_VERSIONS = {/OPENSTACK_API_VERSIONS = {/g' /etc/openstack-dashboard/local_settings.py
# sudo sed -i  's/#    "data-processing": 1.1,/    "data-processing": 1.1,/g' /etc/openstack-dashboard/local_settings.py
# sudo sed -i  's/#    "identity": 3,/    "identity": 3,/g' /etc/openstack-dashboard/local_settings.py
# sudo sed -i  's/#    "volume": 2,/    "volume": 2,/g' /etc/openstack-dashboard/local_settings.py
# sudo sed -i  's/#    "compute": 2,/#/g' /etc/openstack-dashboard/local_settings.py
sudo perl -0777 -i.original -pe 's/#OPENSTACK_API_VERSIONS = \{\n#    "data-processing": 1.1,\n#    "identity": 3,\n#    "image": 2,\n#    "volume": 2,\n#    "compute": 2,\n#}/OPENSTACK_API_VERSIONS = {\n    "data-processing": 1.1,\n    "identity": 3,\n    "image": 2,\n    "volume": 2,\n    "compute": 2,\n}/igs' /etc/openstack-dashboard/local_settings.py

sudo perl -0777 -i.original -pe "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/igs" /etc/openstack-dashboard/local_settings.py

sudo perl -0777 -i.original -pe 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/igs' /etc/openstack-dashboard/local_settings.py

sudo sed -i -e '$aWSGIApplicationGroup %{GLOBAL}' /etc/apache2/conf-available/openstack-dashboard.conf

