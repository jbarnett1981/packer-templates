#!/bin/bash

# Check to see if running with sudo/root and exit if not
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

cd /tmp
git clone https://gitlab.tableausoftware.com/devit/puppet_agent.git
bash /tmp/puppet_agent/install_puppet.sh
rm -rf /tmp/puppet_agent