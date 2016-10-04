#!/bin/bash

# Generate quarter and year string and full image name
QDATE=$(date +%Y)Q$(( ($(date +%-m)-1)/3+1 ))
IMAGE_NAME="CentOS7-DevIT-Final-$QDATE"

# Create packer log env vars
PACKER_LOG=1
PACKER_LOG_PATH=centos7-x64-$QDATE.log

# Replace packer template with current quarter and year image name template
sed "s/IMAGE_NAME/$IMAGE_NAME/g" centos7-x64-cloud.json > centos7-x64-cloud-$QDATE.json

/usr/local/bin/packer build centos7-x64-cloud-$QDATE.json