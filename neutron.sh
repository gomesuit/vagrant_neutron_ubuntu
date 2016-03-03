#!/bin/sh

#apt-get install -y git
#git clone https://github.com/openstack/neutron.git
#cd neutron
#git checkout juno-eol

#rm /usr/bin/python
#ln -s /usr/bin/python3 /usr/bin/python
#wget https://bootstrap.pypa.io/ez_setup.py -O - | python
#easy_install pip

#apt-get install -y python3-dev
#pip install -r requirements.txt -r test-requirements.txt
#./run_tests.sh -N
#python setup.py build
#python setup.py install


#apt-get install -y mysql-server-5.6



apt-get -y install python-mysqldb mysql-server
apt-get -y install rabbitmq-server
#service rabbitmq-server start
rabbitmqctl change_password guest password

mysql -u root -proot -e "create database neutron_ml2 character set utf8;"
#mysql -u root -proot -e "grant all on neutron_ml2.* to 'neutron'@'%';"
mysql -u root -proot -e "set password = password('password')"

echo 'neutron ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
# neutron ALL=(ALL) NOPASSWD: ALL

apt-get -y install neutron-server neutron-plugin-ml2 neutron-l3-agent neutron-dhcp-agent neutron-plugin-openvswitch-agent

cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
auth_strategy = noauth
allow_overlapping_ips = True
policy_file = /etc/neutron/policy.json
debug = True
verbose = True
service_plugins = neutron.services.l3_router.l3_router_plugin.L3RouterPlugin
core_plugin = neutron.plugins.ml2.plugin.Ml2Plugin
rabbit_password = password
rabbit_host = localhost
rpc_backend = neutron.openstack.common.rpc.impl_kombu
state_path = /var/tmp/neutron
lock_path = \$state_path/lock
notification_driver = neutron.openstack.common.notifier.rpc_notifier
[quotas]
[agent]
root_helper = sudo
[database]
connection = mysql://root:password@localhost/neutron_ml2?charset=utf8
[service_providers]
EOF


cat << EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
type_drivers = local,flat,vlan,gre,vxlan
mechanism_drivers = openvswitch,linuxbridge
[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
[ml2_type_vxlan]
[database]
connection = mysql://root:password@localhost/neutron_ml2?charset=utf8
[ovs]
local_ip = 192.168.33.50
[agent]
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF

cat << EOF >> /etc/neutron/l3_agent.ini
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
EOF

service neutron-server restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-plugin-openvswitch-agent restart
service neutron-metadata-agent restart

ovs-vsctl add-br br-ex
# ovs-vsctl add-br br-int
ifconfig br-int up
ifconfig br-ex up

#neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/ml2.conf
#neutron-l3-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/l3_agent.ini
#neutron-dhcp-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini
#neutron-openvswitch-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/ml2.conf



export OS_URL=http://localhost:9696
export OS_TOKEN=admin
export OS_AUTH_STRATEGY=noauth
neutron agent-list

neutron net-create public --tenant-id 1  --router:external True
neutron subnet-create public 10.0.0.0/24 --tenant-id 1
neutron router-create router1 --tenant-id 1
neutron router-gateway-set router1 public
neutron net-create private --tenant-id 1
neutron subnet-create private 192.168.0.0/24 --name subnet1 --tenant-id 1
neutron router-interface-add router1 subnet1
neutron port-create private --device-id=vm1 --binding:host_id=`hostname` --tenant-id 1

ip link add tapb002cdcc-42 type veth peer name vnet0
ifconfig tapb002cdcc-42 hw ether fa:16:3e:bc:2b:69
ifconfig tapb002cdcc-42 up
ovs-vsctl add-port br-int tapb002cdcc-42
ovs-vsctl set Interface tapb002cdcc-42 external-ids:iface-id=c363ac86-9d43-4067-91a1-a82466fc13ce
ovs-vsctl set Interface tapb002cdcc-42 external_ids:attached-mac=fa:16:3e:bc:2b:69
ovs-vsctl set Interface tapb002cdcc-42 external-ids:iface-status=active
ovs-vsctl set Interface tapb002cdcc-42 external-ids:vm-uuid=vm1

neutron port-show c363ac86-9d43-4067-91a1-a82466fc13ce



iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
ifconfig br-ex 10.0.0.1
sysctl -w net.ipv4.ip_forward=1
iptables -I FORWARD -j ACCEPT


ip netns add vm1
ip link set vnet0 netns vm1
ip netns exec vm1 ifconfig vnet0 192.168.0.2
ip netns exec vm1 route add default gw 192.168.0.1

ip netns exec vm1 ping 8.8.8.8 -c 3

