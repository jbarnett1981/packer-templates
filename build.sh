#!/bin/bash
# jbarnett@tableau.com
# 11/29/2016
# Wrapper script to launch linux/win builds of either vmware or openstack variety

MINPARAMS=2

if [ $# -lt "$MINPARAMS" ]
then
  echo
  echo "This script needs at least $MINPARAMS command-line arguments!"
  echo "Ex: bash `basename $0` centos7|ubuntu1404|ubuntu1604|win2k12r2|win2k16 vmware|openstack"
  exit 1
fi

if ! [[ "$1" =~ ^(centos7|ubuntu1404|ubuntu1604|win2k12r2|win2k16)$ ]]; then
  echo "Unsupported argument. Use 'centos7', 'ubuntu1404', 'ubuntu1604', 'win2k16r2' or 'win2k16'."
  exit 1
fi

if ! [[ "$2" =~ ^(vmware|openstack)$ ]]; then
  echo "Unsupported argument. Use 'vmware or 'openstack'"
  exit 1
fi

if [[ $2 = 'openstack' ]]; then
   # source openstack env credentials and run build
   source ./openrc
fi

# Change to working dir
if [[ $1 = win* ]]; then
	cd ./cloud/windows/
	VARS="--var-file vars/$1_vars.json"
else
	cd ./cloud/linux/
fi

# Remove old templates & logs
find . -type f -name '*2[0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]*' | xargs rm -f

# Create packer log env vars
DATE=`date +%Y-%m-%d`
export PACKER_LOG=1
export PACKER_LOG_PATH=$1-x64-$2-$DATE.log

# Remove old kvm bits
rm -rf /kvm-data/$1

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
   # Run packer build
   /usr/local/bin/packer build $VARS "$1"-x64-"$2"-$DATE.json
fi