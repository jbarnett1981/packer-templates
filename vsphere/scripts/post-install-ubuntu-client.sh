#!/bin/bash

# get release vars
RELEASE=$(lsb_release -r | awk '{print $2}')
CODENAME=$(lsb_release -c | awk '{print $2}')

apt-get update

# Add sf-admin to sudoers
echo "sf-admin        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/sf-admin
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
chmod 440 /etc/sudoers.d/sf-admin

# also allow everyone in wheel to sudo without passwd
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# Client specific stuff
wget http://sf-artifactory.solidfire.net/artifactory/sre/bits/sfclient-install-bits.tar
tar -C /opt/ -xvf sfclient-install-bits.tar

cat >> /etc/systemd/system/clientserver.service <<EOF
[Unit]
Description=Client API server
After=clientserver.service

[Service]
Type=simple
ExecStart=/opt/clientserver/bin/run_client_api_server
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# install client packages
apt-get install -y python python-virtualenv libmysqlclient20 sshpass

# setup client packages
/usr/bin/python -m virtualenv --python=/usr/bin/python /opt/clientserver
ln -s /opt/vdbench/vdbench.bash /usr/local/bin/vdbench
ln -s /opt/jre1.8.0_211/bin/java /usr/bin/java
cp /opt/nacl/salt/configs/compress_dir.py /usr/local/bin/compress_dir.py
cp /opt/nacl/salt/configs/create_support_bundle.py /usr/local/bin/create_support_bundle.py
chmod +x  /usr/local/bin/*py
systemctl enable clientserver

# TAS stuff
touch /etc/.TAS_MAGIC_$(date +%Y%m%d%H%M)

# setup TAS authorized keys
mkdir -p /root/.ssh
cat >> /root/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQNHWakwDGjAMQKz+QdWP0FmPrho8yPpPO0UbLFUgdOLfP2AIUERoBBN1apeZ+VuzfPmoq1czS5sBAeoVWVzD/M1dK+gA5k8QSkLfwArY2It7ipIFs1sbUkRDljmImQEaxp7c3Gs+tIR3a37hepn47gxKiPDCOB+BFMTbtN6hgfSKIUOmBma/fixw/6YrCQf5tE8Qe1lG0T2B36gRu8U5KVFXDeDmMnkjjaeUbPUTWAV4Eg2Z7Yhk7XAwiUX8f0sZxL/6oXYIACs72MSz4VyHtm2NiyzPg4ngQJCZtiXiGC0xhl4thSvy5wduTkJGR4SIGxhM8LHFjZYX91Cs4rWHeCUyGZtyKndZVXV2VST4wcwBfee2d22TZIE1KZBTOBl44KHkOtLksfA4Srn9yZfcEmJVLUNOgGpQTdPId2rpCS62/DZdAM3A7jFwJmtKQ2yk2Auu52nDzHKAcmk+0Q8IzGd4rKHNEy5kOwW7Ph569mw3YTsMTySewHVmmOFuQv1kMN1XgIv5bJch2Wq/WSZsX3dOltEF5gDBfoUFHP9+bFLHmqTdbnleJd2HIbzVenI9AFrJUNL/Y106FmX2H207YxP2QP58jS6ZbG9OhIpsLakjTq4oTOswzBoHQsDbQ8t+QydVTOEcp298wYeWQgoEll+GuKzU1YztO0EiTbMyXow== autobot@Mordor
EOF
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

apt-get install -y ntp
timedatectl set-ntp no
systemctl enable ntp.service

# iscsi  tools
apt-get install -y open-iscsi
cat > /etc/iscsi/iscsid.conf << EOF
#
# Open-iSCSI default configuration.
# Could be located at /etc/iscsi/iscsid.conf or ~/.iscsid.conf
#
# Note: To set any of these values for a specific node/session run
# the iscsiadm --mode node --op command for the value. See the README
# and man page for iscsiadm for details on the --op command.
#

################
node.startup = manual

node.conn[0].timeo.login_timeout = 15
node.conn[0].timeo.logout_timeout = 15
node.conn[0].timeo.noop_out_interval = 5
node.conn[0].timeo.noop_out_timeout = 5

discovery.sendtargets.auth.authmethod = CHAP
discovery.sendtargets.auth.username = test
discovery.sendtargets.auth.password = ab1234567890
discovery.sendtargets.iscsi.MaxRecvDataSegmentLength = 32768

node.session.auth.authmethod = CHAP
node.session.auth.username = test
node.session.auth.password = ab1234567890

node.session.timeo.replacement_timeout = 120
node.session.err_timeo.abort_timeout = 15
node.session.err_timeo.lu_reset_timeout = 30
node.session.initial_login_retry_max = 8
node.session.cmds_max = 2048
node.session.queue_depth = 32
node.session.xmit_thread_priority = -20
node.session.iscsi.InitialR2T = No
node.session.iscsi.ImmediateData = Yes
node.session.iscsi.FirstBurstLength = 262144
node.session.iscsi.MaxBurstLength = 16776192
node.conn[0].iscsi.MaxRecvDataSegmentLength = 262144
node.session.iscsi.FastAbort = Yes
EOF

if [ "$RELEASE" == "18.04" ]; then
cat > /etc/netplan/01-netcfg.yaml << EOF
# network plan provided by Core Infrastructure autobuild process
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
      dhcp-identifier: mac
    eth1: 
      dhcp4: yes 
      dhcp-identifier: mac
EOF
fi