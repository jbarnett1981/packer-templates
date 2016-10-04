#!/bin/bash

# Check to see if running with sudo/root and exit if not
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Install puppet repo
rpm -Uvh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

# Install latest puppet agent
yum install -y puppet

# Add in Tableau specific puppet.conf
curl -o /etc/puppet/puppet.conf http://puppetshare.tsi.lan/puppet/Linux/centos.conf

# Enable and start puppet service
systemctl enable puppet.service
systemctl start puppet.service