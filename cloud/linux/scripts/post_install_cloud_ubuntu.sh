### Tableau post config

# Update default editor from nano to vi
sudo update-alternatives --set editor /usr/bin/vim.basic

# Update timezone to PDT
sudo timedatectl set-timezone America/Los_Angeles

# apt-get update
sudo /usr/bin/apt-get update

# Configure resolv.conf
sudo bash -c "/bin/cat > /etc/resolvconf/resolv.conf.d/base <<EOF
search tsi.lan dev.tsi.lan tableaucorp.com db.tsi.lan test.tsi.lan
nameserver 10.26.160.31
nameserver 10.26.160.32
EOF"

sudo /sbin/resolvconf -u

# Install required tools
sudo /usr/bin/apt-get install -y openssh-server build-essential nfs-common git smbclient cifs-utils wget sysv-rc-conf vim

# Replace sudoers file

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

## Configure sysconfig/snmpd
#echo "OPTIONS=\"-LS0-5d -Lf /dev/null -p /var/run/snmpd.pid -a\"" >> /etc/sysconfig/snmpd

### Disable core dumps by default
sudo bash -c "/bin/echo '* soft core 0' >> /etc/security/limits.conf"
sudo bash -c "/bin/echo '* hard core 0' >> /etc/security/limits.conf"

### Protect root directory
sudo /bin/chmod -R go-rwx /root

### Configure Manufacturer variable
hwtype=$(dmesg | grep "DMI:" | awk '{print $4}')

#### Install Latest Dell OMSA if host is type "Dell"
if [ "$hwtype" = "Dell" ]; then

/bin/echo 'deb http://linux.dell.com/repo/community/ubuntu precise openmanage' | sudo tee -a /etc/apt/sources.list.d/linux.dell.com.sources.list
/usr/bin/gpg --keyserver pool.sks-keyservers.net --recv-key 1285491434D8786F
/usr/bin/gpg -a --export 1285491434D8786F | sudo apt-key add -
/usr/bin/apt-get update
/usr/bin/apt-get install -y srvadmin-all
fi

if [[ $hwtype = *"VMware"* ]]; then
# Vmware Virtual Machine
/usr/bin/apt-get install -y open-vm-tools
fi

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