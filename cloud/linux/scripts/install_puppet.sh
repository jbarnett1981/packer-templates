#!/bin/bash

# Check to see if running with sudo/root and exit if not
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

swver=$(lsb_release -d | awk '{print $2}')

if [ $swver = "CentOS" ]; then

   # Install puppet repo
   rpm -Uvh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

   # Install latest puppet agent
   yum install -y puppet

   # Add in Tableau specific puppet.conf
   curl -o /etc/puppet/puppet.conf http://puppetshare.dev.tsi.lan/puppet/Linux/PuppetOG/puppet.conf

   # Enable and start puppet service
   systemctl enable puppet.service
   systemctl start puppet.service
fi

if [ $swver = "Ubuntu" ]; then

   # Install apt repo
   cd /tmp
   wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
   sudo dpkg -i /tmp/puppetlabs-release-trusty.deb
   sudo apt-get update

   # Install latest puppet agent
   sudo apt-get install -y puppet

   # Add in Tableau specific puppet.conf
   curl -o /etc/puppet/puppet.conf http://puppetshare.dev.tsi.lan/puppet/Linux/PuppetOG/puppet.conf

   # Enable and start puppet service
   sudo sed -i 's/^START.*/START=yes/' /etc/default/puppet
   sudo service puppet start
fi