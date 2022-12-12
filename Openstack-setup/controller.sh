

echo "[TASK 1] setup keystone"

sudo mysql -e "CREATE DATABASE keystone"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'openstack'"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'openstack'"

sudo apt install keystone -y

sudo sed -i 's/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql+pymysql:\/\/keystone:openstack@controller\/keystone/g' /etc/keystone/keystone.conf
sudo sed -i 's/#provider = fernet/provider = fernet/g' /etc/keystone/keystone.conf

sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password openstack --bootstrap-admin-url http://controller:5000/v3/ --bootstrap-internal-url http://controller:5000/v3/ --bootstrap-public-url http://controller:5000/v3/ --bootstrap-region-id RegionOne

sudo sed -i '$ a ServerName controller' /etc/apache2/apache2.conf

sudo service apache2 restart

export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3