#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Test if hostname is > 15 characters, and if so truncate and add to samba netbios name param
RED='\033[0;31m'
NC='\033[0m'
HOST=$(hostname -s)
if [ ${#HOST} -gt 15 ]; then
   echo -e "${RED}WARNING${NC}: This instance was created with a name longer than 15 characters"
   echo -e "${RED}WARNING${NC}: Please delete this instance and create one with a name of 15 characters or less"
   exit 1
fi

cd /tmp
git clone https://gitlab.tableausoftware.com/devit/sssd.git
bash /tmp/sssd/domain_join_kerb_cloud.sh
rm -rf /tmp/sssd