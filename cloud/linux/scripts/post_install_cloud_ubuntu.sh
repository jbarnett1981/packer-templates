### Tableau post config

### Configure Manufacturer variable
hwtype=$(dmesg | grep "DMI:" | awk '{print $4}')

#### Install VMware Tools if host is type "VMware"
if [[ $hwtype = *"VMware"* ]]; then
# Add it and user and set passwd
sudo /usr/sbin/useradd -m -d /home/it -s /bin/bash -p '$1$6982c48E$5Ap/qdWzYDGG.8fqsNSpz0' -G sudo,audio,cdrom,video it

# Vmware Virtual Machine
sudo /usr/bin/apt-get install -y open-vm-tools

# Allow sudo without tty
sudo bash -c 'sed -i "s|Defaults    requiretty|Defaults    !requiretty|g" /etc/sudoers'

sudo sed -i '/exit 0/d' /etc/rc.local
sudo bash -c '/bin/echo "if [ -f /home/devlocal/EXPAND_ROOT ]; then sudo bash /home/devlocal/EXPAND_ROOT && rm /home/devlocal/EXPAND_ROOT && sudo reboot; fi" >> /etc/rc.local'

fi

# Update default editor from nano to vi
sudo update-alternatives --set editor /usr/bin/vim.basic

# Update timezone to PDT
sudo timedatectl set-timezone America/Los_Angeles

# apt-get update
sudo /usr/bin/apt-get update
sudo /usr/bin/apt-get -y upgrade
sudo /usr/bin/apt-get -y autoremove

# Configure resolv.conf
sudo bash -c "/bin/cat > /etc/resolvconf/resolv.conf.d/base <<EOF
search tsi.lan dev.tsi.lan tableaucorp.com db.tsi.lan test.tsi.lan
nameserver 10.26.160.31
nameserver 10.26.160.32
EOF"

sudo /sbin/resolvconf -u

# Install required tools
sudo /usr/bin/apt-get install -y openssh-server build-essential ntp nfs-common git smbclient cifs-utils wget sysv-rc-conf vim zip tree

# # Add Tableau DevIT sudoers file
# sudo bash -c "cat > /etc/sudoers.d/tableau-devit <<EOF
# # Tableau DevIT Managed
# # Allow zabbix user to restart puppet agent
# zabbix ALL=NOPASSWD: /etc/init.d/puppet restart

# # Allow following accounts full admin with no password prompt
# builder  ALL=(ALL)  NOPASSWD: ALL

# # Allow following groups full admin with password prompt
# %devit  ALL=(ALL)   NOPASSWD: ALL
# %development    ALL=(ALL)       ALL
# EOF"

# Disable requiretty in sudoers
sudo bash -c 'sed -i "s|Defaults    requiretty|Defaults    !requiretty|g" /etc/sudoers'

### base build is complete ###

#######################################################
### Tableau Custom Configurations ###

sudo /usr/bin/apt-get install -y snmpd
sudo cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
sudo bash -c "/bin/cat > /etc/snmp/snmpd.conf <<EOF
com2sec local     localhost       public
com2sec mynetwork 10.0.0.0/8      public
group MyRWGroup v1         local
group MyRWGroup v2c        local
group MyRWGroup usm        local
group MyROGroup v1         mynetwork
group MyROGroup v2c        mynetwork
group MyROGroup usm        mynetwork
view all    included  .1                               80
access MyROGroup ""      any       noauth    exact  all    none   none
access MyRWGroup ""      any       noauth    exact  all    none   none
syslocation Tableau DevIT, Internap
syscontact DevIT_Infrastructure <devit-inf@tableausoftware.com>
proc sshd
disk / 15%
load 8 8 8
EOF"

### Disable core dumps by default
sudo bash -c "/bin/echo '* soft core 0' >> /etc/security/limits.conf"
sudo bash -c "/bin/echo '* hard core 0' >> /etc/security/limits.conf"

### Configure cron usage
sudo bash -c 'echo "root" > /etc/cron.allow'
sudo bash -c 'echo "ALL" > /etc/cron.deny'
sudo chmod 644 /etc/cron.allow /etc/cron.deny
sudo chmod 0400 /etc/crontab

#### Configure sshd
sudo bash -c 'cat >> /etc/ssh/sshd_config <<EOF
ClientAliveInterval 300
Banner /etc/issue
EOF'

### Protect root directory
sudo /bin/chmod -R go-rwx /root

### Add login banner
sudo bash -c "cat > /etc/issue <<EOF
*** WARNING ***

THIS IS A PRIVATE COMPUTER SYSTEM. It is for authorized use only.
Users (authorized or unauthorized) have no explicit or implicit
expectation of privacy. THERE IS NO RIGHT OF PRIVACY IN THIS SYSTEM.
System personnel may disclose any potential evidence of crime found
on computer systems for any reason.  USE OF THIS SYSTEM BY ANY USER,
AUTHORIZED OR UNAUTHORIZED, CONSTITUTES CONSENT TO THIS MONITORING,
INTERCEPTION, RECORDING, READING, COPYING, or CAPTURING and DISCLOSURE.

EOF"
sudo cp -f /etc/issue /etc/issue.net

### Configure /tmp cleanup for every 7 days (default every boot, which breaks startup scripts placed in this dir)
sudo sed -i '/TMPTIME/c\TMPTIME=7' /etc/default/rcS

# Delete yourself
rm -f $0