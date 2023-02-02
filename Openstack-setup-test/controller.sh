

echo "[TASK 1] setup keystone"

sudo mysql -e "CREATE DATABASE keystone"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$2'"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$2'"

sudo apt install keystone -y

sudo sed -i 's/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql+pymysql:\/\/keystone:openstack@controller\/keystone/g' /etc/keystone/keystone.conf
sudo sed -i 's/#provider = fernet/provider = fernet/g' /etc/keystone/keystone.conf

sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password $2 --bootstrap-admin-url http://controller:5000/v3/ --bootstrap-internal-url http://controller:5000/v3/ --bootstrap-public-url http://controller:5000/v3/ --bootstrap-region-id RegionOne

sudo sed -i '$ a ServerName controller' /etc/apache2/apache2.conf

sudo service apache2 restart

export OS_USERNAME=admin
export OS_PASSWORD=$2
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

echo "[TASK 2] setup openrc.sh"
cat >>/home/hspo/admin-openrc.sh<<EOF
export OS_USERNAME=admin
export OS_PASSWORD=$2
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
sudo chmod +x /home/hspo/admin-openrc.sh
# setup file for vagrant
cat >>admin-openrc.sh<<EOF
export OS_USERNAME=admin
export OS_PASSWORD=$2
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
sudo chmod +x admin-openrc.sh

sudo . admin-openrc.sh

sudo openstack user create --domain default --password $2 glance
sudo openstack role add --project service --user glance admin
sudo openstack service create --name glance --description "OpenStack Image" image
sudo openstack endpoint create --region RegionOne image public http://controller:9292
sudo openstack endpoint create --region RegionOne image internal http://controller:9292
sudo openstack endpoint create --region RegionOne image admin http://controller:9292



echo "[TASK 3] setup Glance"

sudo mysql -e "CREATE DATABASE glance"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$2'"
sudo mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$2'"