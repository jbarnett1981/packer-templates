#!/bin/bash

MINPARAMS=1

if [ $# -lt "$MINPARAMS" ]
then
  echo
  echo "This script needs at least $MINPARAMS command-line arguments!"
  echo "Ex: bash `basename $0` centos7|ubuntu1404|ubuntu1604"
  exit 1
fi

if ! [[ "$1" =~ ^(centos7|ubuntu1404|ubuntu1604)$ ]]; then
  echo "Unsupported argument. Use 'centos7 or 'ubuntu1404' or 'ubuntu1604'."
  exit 1
fi

# Change to working dir
cd /usr/local/devit/packer/cloud/linux/
. openrc

# Get latest data from repo
git pull

# Destroy known_hosts so packer can ssh using recycled openstack IP
rm -f /root/.ssh/known_hosts

# Create packer log env vars
DATE=`date +%Y%m%d`
PACKER_LOG=1
PACKER_LOG_PATH=centos7-x64-$QDATE-$DATE.log

# Generate quarter and year string and full image name
QDATE=$(date +%Y)q$(( ($(date +%-m)-1)/3+1 ))
IMAGE_NAME="$1-devit-final-$QDATE"

# Replace packer template with current quarter and year image name template
sed "s/IMAGE_NAME/$IMAGE_NAME/g" "$1"-x64-cloud.json > "$1"-x64-cloud-$QDATE.json

/usr/local/bin/packer build "$1"-x64-cloud-$QDATE.json