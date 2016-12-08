#!/bin/bash

# Remove NetworkManager, it sucks
export IFCFG=/etc/sysconfig/network-scripts/ifcfg-eth0
export HWADDR=$(ip addr show dev eth0 | grep ether | awk '{print $2}')

systemctl stop NetworkManager
chkconfig NetworkManager off
yum erase -y NetworkManager
chkconfig network on

# Add/change PEERDNS=no in ifcfg-eth0
if grep -q PEERDNS "$IFCFG"; then sudo -E sed -i 's/^PEERDNS.*/PEERDNS=no/' $IFCFG; else sudo -E bash -c 'echo "PEERDNS=no" >> $IFCFG'; fi

# Add correct HWADDR to ifcfg-eth0
if grep -q HWADDR "$IFCFG"; then sudo -E sed -i "s/^HWADDR.*/HWADDR=${HWADDR}/" $IFCFG; else sudo -E bash -c 'echo "HWADDR=${HWADDR}" >> $IFCFG'; fi

# And finally start the network service
systemctl start network

# Cleanup
rm -f /etc/cron.d/update_ifcfg
/sbin/reboot