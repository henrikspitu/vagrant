#!/bin/bash


echo "[TASK 1] srtup Block Storage"
sudo su

apt update -y
apt install -y lvm2 thin-provisioning-tools crudini

#fdisk -l

# Disk managed by Vagrant

#BUT need fdisk to delete the partition first

#fdisk /dev/sdb -d -w
#pvcreate /dev/sdb
#vgcreate cinder-volumes /dev/sdb




#TODO Get this to work
#sudo sed -i 's/# filter = [ "a|.*/|" ]/filter = [ "a/sda/", "a/sdb/", "r/.*/"]/g' /etc/lvm/lvm.conf

apt install -y cinder-volume

crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$3@controller/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:openstack@controller

crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri = http://controller:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password $3



crudini --set /etc/cinder/cinder.conf DEFAULT my_ip $1


crudini --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
crudini --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes
crudini --set /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
crudini --set /etc/cinder/cinder.conf lvm iscsi_helper tgtadm

crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm

crudini --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://controller:9292
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

service tgt restart
service cinder-volume restart