#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Remove NetworkManager, it sucks
IFCFG=/etc/sysconfig/network-scripts/ifcfg-eth0
HWADDR=$(ip addr show dev eth0 | grep ether | awk '{print $2}')
echo $HWADDR
systemctl stop NetworkManager
chkconfig NetworkManager off
yum erase -y NetworkManager
chkconfig network on

# Add/change PEERDNS=no in ifcfg-eth0
if grep -q PEERDNS "$IFCFG"; then sed -i "s/^PEERDNS.*/PEERDNS=no/g" $IFCFG; else echo "PEERDNS=no" >> $IFCFG; fi

# Add correct HWADDR to ifcfg-eth0
if grep -q HWADDR "$IFCFG"; then sed -i "s/^HWADDR.*/HWADDR=$HWADDR/g" $IFCFG; else echo "HWADDR=$HWADDR" >> $IFCFG; fi

# And finally start the network service
systemctl start network

# Cleanup
rm -f /etc/cron.d/update_ifcfg