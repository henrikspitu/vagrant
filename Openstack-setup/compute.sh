#!/bin/bash
echo "[TASK 1] setup Novo"
sudo su
apt update
apt install -y nova-compute crudini
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:$3@controller

# Configure Identity Service access
crudini --set /etc/nova/nova.conf api auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_auth auth_uri http://controller:5000
crudini --set /etc/nova/nova.conf keystone_auth auth_url http://controller:35357
crudini --set /etc/nova/nova.conf keystone_auth memcached_servers controller:11211
crudini --set /etc/nova/nova.conf keystone_auth auth_type password
crudini --set /etc/nova/nova.conf keystone_auth project_domain_name default
crudini --set /etc/nova/nova.conf keystone_auth user_domain_name default
crudini --set /etc/nova/nova.conf keystone_auth project_name service
crudini --set /etc/nova/nova.conf keystone_auth username nova
crudini --set /etc/nova/nova.conf keystone_auth password $3

# Configure support for Networking Service
crudini --set /etc/nova/nova.conf DEFAULT my_ip $1
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

# Configure vnc Remote Console access on Compute Node
crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $1
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://10.0.0.21:6080/vnc_auto.html

# Configure Glance location
crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292

# Configure Lock Path for Oslo Concurrency
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# Configure Placement API
crudini --set /etc/nova/nova.conf placement os_region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:35357/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password $3

# Remove log_dir parameter in DEFAULT section
crudini --del /etc/nova/nova.conf DEFAULT log_dir

# qemu emulator
crudini --set /etc/nova/nova-compute.conf libvirt virt_type qemu

service nova-compute restart

echo "Nova DONE on Compute"

# enrolle on controller

sshpass -p $5 ssh -o StrictHostKeyChecking=no $4@controller  'echo "hello" > hello.log'
sshpass -p $5 ssh -o StrictHostKeyChecking=no $4@controller  'sudo -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova'
sshpass -p $5 ssh -o StrictHostKeyChecking=no $4@controller  'sudo su; source /home/vagrant/admin-openrc; openstack compute service list'

echo "registration on controller done"

echo "[TASK ] setup Neutron"
apt update
apt install -y neutron-linuxbridge-agent

crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$3@controller

crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $3

# Configure provider Virtual Network mapping to Physical Interface
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth3
# Enable VXLAN for Self-service Networks, configure IP address of the Management Interface handling VXLAN traffic
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $1
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
# Enable security groups and configure the Linux bridge iptables firewall driver
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:35357
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $3

service nova-compute restart			
service neutron-linuxbridge-agent restart		

echo "verify neutron on controller"
sshpass -p $5 ssh -o StrictHostKeyChecking=no $4@controller  'sudo su; source /home/vagrant/admin-openrc; openstack network agent list'