#!/bin/bash

MINPARAMS=2

if [ $# -lt "$MINPARAMS" ]
then
  echo
  echo "This script needs at least $MINPARAMS command-line arguments!"
  echo "Ex: bash `basename $0` centos7|ubuntu1404|ubuntu1604 vmware|openstack"
  exit 1
fi

if ! [[ "$1" =~ ^(centos7|ubuntu1404|ubuntu1604)$ ]]; then
  echo "Unsupported argument. Use 'centos7 or 'ubuntu1404' or 'ubuntu1604'."
  exit 1
fi

if ! [[ "$2" =~ ^(vmware|openstack)$ ]]; then
  echo "Unsupported argument. Use 'vmware or 'openstack'"
  exit 1
fi

# Change to working dir
cd /usr/local/devit/packer/cloud/linux/

# Remove old templates & logs
find . -type f -name '*2[0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]*' | xargs rm -f

# Create packer log env vars
DATE=`date +%Y-%m-%d`
export PACKER_LOG=1
export PACKER_LOG_PATH=$1-x64-$2-$DATE.log

#QDATE=$(date +%Y)q$(( ($(date +%-m)-1)/3+1 ))
IMAGE_NAME="$1-$2-$DATE"

# Replace packer template with current quarter and year image name template
sed "s/IMAGE_NAME/$IMAGE_NAME/g" "$1"-x64-"$2".json > "$1"-x64-"$2"-$DATE.json

# If VMWare, run vmware.py to cleanup stale orphan and create template
if [ $2 = "vmware" ]; then
   # Run packer build
   /usr/local/bin/packer build --var-file vmware/packer-vmware-info.json "$1"-x64-"$2"-$DATE.json
   python vmware.py $1
else
   # source openstack env credentials and run build
   source openrc
   /usr/local/bin/packer build "$1"-x64-"$2"-$DATE.json
fi