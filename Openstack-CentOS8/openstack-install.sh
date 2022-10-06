#!/bin/bash

# network interface
#ifcfg-eth1

#sudo yum install -y centos-release-openstack-train
#sudo yum install -y yum-utils
#sudo yum-config-manager --enable openstack-train 
#sudo yum update -y
#sudo yum install -y openstack-packstack

# Note Takes a long time
# Command doc: https://github.com/redhat-openstack/packstack/blob/master/docs/packstack.rst

#sudo packstack --allinone --provision-demo=n --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-neutron-ml2-mechanism-drivers=openvswitch --os-neutron-l2-agent=openvswitch --os-neutron-ovs-bridge-interfaces=br-ex:eth1 --os-neutron-ml2-type-drivers=vxlan,flat --os-neutron-ml2-tenant-network-types=vxlan